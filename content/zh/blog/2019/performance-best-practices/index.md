---
title: "最佳实践：Service Mesh 基准性能测试"
description: "评估 Istio 数据平面性能的工具和指南。"
publishdate: 2019-07-09
last_update: 2019-09-05
subtitle:
attribution: Megan O'Keefe (Google), John Howard (Google), Mandar Jog (Google)
keywords: [performance,scalability,scale,benchmarks]
---

服务网格为应用部署增加了很多功能，包括[流量策略](/zh/docs/concepts/what-is-istio/#traffic-management)、[可观察性](/zh/docs/concepts/what-is-istio/#observability)和[安全通信](/zh/docs/concepts/what-is-istio/#security)。但是，无论是时间（增加的延迟）还是资源（CPU 周期），向环境中添加服务网格都是有代价的。要就服务网格是否适合您的情况做出明智的决定，评估应用与服务网格一起部署时的性能非常重要。

今年早些时候，我们发布了关于 Istio 1.1 性能改进的[博客](/zh/blog/2019/istio1.1_perf/)。在发布 [Istio 1.2](/zh/news/releases/1.2.x/announcing-1.2) 之后，我们希望提供指导和工具，以帮助您在可用于生产的 Kubernetes 环境中对 Istio 的数据平面性能进行基准测试。

总体而言，我们发现 Istio [sidecar 代理](/zh/docs/ops/deployment/architecture/#envoy)的延迟取决于并发连接数。以每秒 1000 个请求（RPS）的速度，通过 16 个连接，Istio 延迟在 50% 时增加 **3 毫秒**，在 99% 时增加 **10 毫秒**。

在 [Istio Tools 仓库](https://github.com/istio/tools/tree/3ac7ab40db8a0d595b71f47b8ba246763ecd6213/perf/benchmark)中，您将找到用于测量 Istio 数据平面性能的脚本和说明，以及有关如何使用另一服务网格实现 [Linkerd](https://linkerd.io) 运行脚本的其他说明。在我们详细介绍性能测试框架的每个步骤的一些最佳实践时，请[遵循](https://github.com/istio/tools/tree/3ac7ab40db8a0d595b71f47b8ba246763ecd6213/perf/benchmark#setup)。

## 1. 使用生产就绪的 Istio 安装{#1-use-a-production-ready-Istio-installation}

为了准确地大规模度量服务网格的性能，使用[适当大小的](https://github.com/istio/tools/tree/3ac7ab40db8a0d595b71f47b8ba246763ecd6213/perf/istio-install#istio-setup) Kubernetes 集群很重要。我们使用三个工作节点进行测试，每个工作节点至少具有 4 vCPU 和 15 GB 的内存。

然后，在该群集上使用可用于生产的 Istio **安装配置文件** 很重要。这使我们能够实现面向性能的设置，例如控制平面 pod 自动伸缩，并确保资源限制适用于繁重的流量负荷。[默认](/zh/docs/setup/install/helm/#安装步骤) Istio 安装适用于大多数基准测试用例。为了进行广泛的性能基准测试，并提供数千种注入代理的服务，我们还提供了[调整后的 Istio 安装](https://github.com/istio/tools/blob/3ac7ab40db8a0d595b71f47b8ba246763ecd6213/perf/istio-install/values.yaml)，可为 Istio 控制平面分配额外的内存和 CPU。

{{< warning_icon >}} Istio 的 [demo 安装](/zh/docs/setup/getting-started/)不适合进行性能测试，因为它被设计为部署在小型试用群集中，并且具有完整的跟踪和访问日志，可显示 Istio 的功能。

## 2. 专注于数据平面{#2-focus-on-the-data-plane}

我们的基准测试脚本专注于评估 Istio 数据平面：{{<gloss>}}Envoy{{</gloss>}} 代理，可在应用容器之间进行流量调度。为什么要关注数据平面？因为在大规模使用大量应用容器时，数据平面的 **内存** 和 **CPU** 使用率很快就会超过 Istio 控制平面。让我们看一个具体的例子：

假设您运行了 2,000 个注入 Envoy 的 pod，每个 pod 每秒处理 1,000 个请求。每个代理使用 50 MB 的内存，并且要配置所有这些代理，Pilot 使用 1 vCPU 和 1.5 GB 的内存。所有的资源中，Istio 数据平面（所有 Envoy 代理的总和）使用了 100 GB 的内存，而 Pilot 只使用了 1.5 GB。

考虑到 **延迟**，关注数据平面性能也很重要。这是因为大多数应用的请求会通过 Istio 数据平面，而不是通过控制平面。但是，有两个例外：

1. **遥测报告：** 每个代理将原始遥测数据发送到 {{<gloss>}}Mixer{{</gloss>}}，Mixer 将其处理为度量，跟踪和其他遥测。原始遥测数据类似于访问日志，因此要付出一定的代价。访问日志处理会消耗 CPU，并使工作线程无法处理下一个工作单元。在更高的吞吐量场景下，下一个工作单元更有可能在队列中等待被工作者接走。这可能导致 Envoy 的长尾延迟（99%）。
1. **自定义策略检查：** 当使用[自定义 Istio 策略适配器](/zh/docs/concepts/observability/)时，策略检查位于请求路径上。这意味着数据路径上的请求 header 和 metadata 将被发送到控制平面（Mixer），从而导致更高的请求延迟。**注意：** 这些策略检查[默认情况下处于禁用状态](/zh/docs/reference/config/installation-options/#global-options)，因为最常见的策略用例（[RBAC](/zh/docs/reference/config/security/istio.rbac.v1alpha1)）完全由 Envoy 代理执行。

当 [Mixer V2](https://docs.google.com/document/d/1QKmtem5jU_2F3Lh5SqLp0IuPb80_70J7aJEYu4_gS-s) 将所有策略和遥测功能直接移到代理中时，这两个例外都会在将来的 Istio 版本中消失。

接下来，在大规模测试 Istio 的数据平面性能时，不仅要以每秒递增的请求进行测试，而且还要以越来越多的 **并发** 连接进行测试，这一点很重要。这是因为现实世界中的高吞吐量流量来自多个客户端。我们[提供了脚本](https://github.com/istio/tools/tree/3ac7ab40db8a0d595b71f47b8ba246763ecd6213/perf/benchmark#run-performance-tests)允许您以递增的 RPS 对任意数量的并发连接执行相同的负载测试。

最后，我们的测试环境可以测量两个 pod 之间少量的请求。客户端 pod 是 [Fortio](http://fortio.org/)，它将流量发送到服务端 pod。

为什么只用两个 pod 测试？因为增加吞吐量（RPS）和连接（线程）对 Envoy 的性能的影响比增加服务注册表的总大小（或 Kubernetes 集群中 Pod 和服务的总数）更大。当服务注册表的大小增加时，Envoy 必须跟踪更多的端点，并且每个请求的查找时间确实增加了，但是增加了一个很小的常数。如果您有许多服务，并且此常数成为延迟问题，则 Istio 提供 [Sidecar 资源](/zh/docs/reference/config/networking/sidecar/)，它使您可以限制每个 Envoy 知道的服务。

## 3. 有/无 度量的代理{#3-measure-with-and-without-proxies}

尽管 Istio 的许多特性，例如[双向 TLS 身份验证](/zh/docs/concepts/security/#mutual-TLS-authentication)，都依赖于应用 pod 的 Envoy 代理，但是您可以[选择性地禁用](/zh/docs/setup/additional-setup/sidecar-injection/#disabling-or-updating-the-webhook)一些网格服务的 sidecar 代理注入。在扩展 Istio 以进行生产时，您可能需要将 sidecar 代理增量添加到工作负载中。

为此，测试脚本提供了[三种不同模式](https://github.com/istio/tools/tree/3ac7ab40db8a0d595b71f47b8ba246763ecd6213/perf/benchmark#run-performance-tests)。当请求同时通过客户端和服务器代理（`both`）、仅通过服务器代理（`serveronly`）和都不通过代理（`baseline`）时，这些模式将分析 Istio 的性能。

您还可以在性能测试期间禁用 [Mixer](/zh/docs/concepts/observability/) 以停止 Istio 的遥测，这将得到与 Mixer V2 工作完成时我们期望的性能相符的结果。Istio 还支持 [Envoy 本地遥测](https://github.com/istio/istio/wiki/Envoy-native-telemetry)，其功能类似于禁用 Istio 的遥测。

## Istio 1.2 性能{#Istio-1-2-performance}

让我们看看如何使用该测试环境来分析 Istio 1.2 数据平面的性能。我们还提供了运行 [Linkerd 数据平面的相同性能测试](https://github.com/istio/tools/tree/3ac7ab40db8a0d595b71f47b8ba246763ecd6213/perf/benchmark/linkerd)的说明。Linkerd 目前仅支持延迟基准测试。

为了衡量 Istio sidecar 的代理延迟，我们考虑在 50%、90% 和 99% 时不断增加并发连接数量，从而保持了请求吞吐量（RPS）不变。

我们发现，通过 16 个并发连接和 1000 RPS，当请求同时通过客户端和服务器代理传输时，Istio 会在基线（P50）上增加 **3ms**。（从绿色线 `both` 中减去粉红色线 `base`）在 64 个并发连接上，Istio 在基线上增加了 **12ms**，但是禁用 Mixer（`nomixer_both`）后，Istio 仅增加了 **7ms**。

{{< image  width="75%" ratio="60%"
    link="./latency_p50.png"
    alt="Istio sidecar 代理, 50% 时的延迟"
    title="Istio sidecar 代理, 50% 时的延迟"
    caption=""
    >}}

在 90% 时，有 16 个并发连接，Istio 增加 **6ms**；在 64 个连接的情况下，Istio 增加了 **20ms**。

{{< image width="75%" ratio="60%"
    link="./latency_p90.png"
    alt="Istio sidecar 代理, 90% 时的延迟"
    title="Istio sidecar 代理, 90% 时的延迟"
    caption=""
    >}}

最后，在具有 16 个连接的 99% 时，Istio 在基线之上增加了 **10ms**。在 64 个连接处，Istio 使用 Mixer 增加 **25ms**，不使用 Mixer 则增加 **10ms**。

{{< image  width="75%" ratio="60%"
    link="./latency_p99.png"
    alt="Istio sidecar 代理, 99% 时的延迟"
    title="Istio sidecar 代理, 99% 时的延迟"
    caption=""
    >}}

对于 CPU 使用率，我们以不断增加的请求吞吐量（RPS）和恒定数量的并发连接进行了测量。我们发现启用了 Mixer 的 Envoy 在 3000 RPS 时的最大 CPU 使用率是 **1.2 vCPU**。在 1000 RPS 时，一个 Envoy 大约使用了 50% 的 CPU。

{{< image  width="75%" ratio="60%"
    link="./cpu_max.png"
    alt="Istio sidecar 代理，最大 CPU 使用率"
    title="Istio sidecar 代理，最大 CPU 使用率"
    caption=""
    >}}

## 总结{#summary}

在对 Istio 的性能进行基准测试的过程中，我们吸取了一些重要的经验教训：

- 使用模仿生产的环境。
- 专注于数据平面流量。
- 基于基准进行测量。
- 增加并发连接以及总吞吐量。

对于在 16 个连接上具有 1000 RPS 的网格，Istio 1.2 仅在 50% 的基础上增加了 **3 毫秒** 的基准延迟。

{{< tip >}}
Istio 的性能取决于您的具体设置和流量负载情况。由于存在这种差异，请确保您的测试设置能够准确反映您的生产工作负载。要试用基准测试脚本，请转到 [Istio Tools 库](https://github.com/istio/tools/tree/3ac7ab40db8a0d595b71f47b8ba246763ecd6213/perf/benchmark)。
{{< /tip >}}

另外，请查阅 [Istio 性能和可伸缩性指南](/zh/docs/ops/deployment/performance-and-scalability)获取最新的性能数据。感谢您的阅读，祝您基准测试愉快！

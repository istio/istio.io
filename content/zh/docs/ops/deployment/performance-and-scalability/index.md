---
title: 性能和可扩展性
description: 介绍 Istio 的性能和可扩展性。
weight: 30
keywords:
  - performance
  - scalability
  - scale
  - benchmarks
aliases:
  - /zh/docs/performance-and-scalability/overview
  - /zh/docs/performance-and-scalability/microbenchmarks
  - /zh/docs/performance-and-scalability/performance-testing-automation
  - /zh/docs/performance-and-scalability/realistic-app-benchmark
  - /zh/docs/performance-and-scalability/scalability
  - /zh/docs/performance-and-scalability/scenarios
  - /zh/docs/performance-and-scalability/synthetic-benchmarks
  - /zh/docs/concepts/performance-and-scalability
  - /zh/docs/ops/performance-and-scalability
owner: istio/wg-environments-maintainers
test: n/a
---

Istio 以十分便捷且对应用程序透明的方式，为已部署的服务创建网络，提供完善的网络功能，包括：路由规则、负载均衡、服务到服务的验证以及监控等。Istio 致力于用最小的资源开销实现最大的便易性，旨在支持高请求率非常大规模的网格，同时让延迟最小化。

Istio 的数据平面组件，即 Envoy 代理，用来处理通过系统的数据流。控制平面组件 Istio 负责配置数据平面。数据平面和控制平面有不同的性能问题。

## Istio {{< istio_release_name >}} 性能总结 {#performance-summary-for-Istio}

[`Istio 负载测试`](https://github.com/istio/tools/tree/{{< source_branch_name >}}/perf/load)网格包含了 **1000** 个服务和 **2000** 个 Sidecar，全网格范围内，QPS 为 70,000。在使用 Istio {{< istio_release_name >}} 运行测试后，我们得到了如下结果：

- 通过代理的 QPS 有 1000 时，Envoy 使用了 **0.35 vCPU** 和 **40 MB 内存**。
- 网格总的 QPS 为 1000 时，`istio-telemetry` 服务使用了 **0.6 vCPU**。
- Istiod 使用了 **1 vCPU** 和 1.5 GB 内存。
- 90% 的情况 Envoy 代理只增加了 2.65 ms 的延迟。

## 控制平面性能 {#control-plane-performance}

Istiod 根据用户编写的配置文件和系统当前状态来配置 Sidecar 代理。在 Kubernetes 环境中，自定义资源定义（CRDs）和部署构成了系统的配置和状态。像网关和虚拟服务这样的 Istio 配置对象提供了用户编写配置的能力。Istiod 综合处理配置和系统状态，生成代理的配置信息，这些配置和系统状态源自 Kubernetes 环境和用户编写的配置文件。

控制平面支持数千个服务，分布在数千个 Pod 上，所需的用户自有虚拟服务和其它配置对象的数量级与之类似。Istiod 的 CPU 和内存需求随着配置和可能的系统状态的数量量而扩展。CPU 消耗的变化取决于以下因素：

- 部署改变的频率。
- 配置改变的频率。
- 连接到 Istiod 的代理数量。

这部分本身是水平可伸缩的。当[命名空间隔离](/zh/docs/reference/config/networking/sidecar/)选项被打开，一个单一的 Istiod 实例仅用 1 vCPU 和 1.5 GB 的内存就可以支持 1000 个服务和 2000 个 Sidecar。您可以增加 Istiod 实例的数量来降低它花在推送配置到所有代理的耗时。

## 数据平面性能 {#data-plane-performance}

数据平面的性能受很多因素影响，例如：

- 客户端连接数量
- 目标服务接收请求率
- 请求和响应的大小
- 代理工作线程的数量
- 协议
- CPU 核数
- 代理过滤器的数量和类型，特别是 Mixer 过滤器

根据上述因素来度量延迟、吞吐量以及代理的 CPU 和内存消耗。

### CPU 和内存 {#CPU-and-memory}

由于 Sidecar 代理会在数据路径上执行其他工作，因此会占用 CPU 和内存。 从 Istio 1.7 开始，代理每 1000 个请求每秒消耗约 0.5 个 vCPU。

代理的内存消耗取决于它的总体配置状态。大量的侦听器，集群和路由会增加内存使用率。Istio 1.1 引入了名称空间隔离，来限制发送到代理的配置范围。在一个比较大的命名空间中，代理将消耗大约 50 MB 的内存。

由于代理通常不缓存通过的数据，请求速率不会影响内存消耗。

### 延迟 {#latency}

因为 Istio 在数据路径上注入了一个 Sidecar 代理，所以延迟是重要的考量因素。Istio 向代理添加了身份验证、Mixer 过滤器和元数据交换过滤器。每一个额外的过滤器都会增加代理内的路径长度并影响延迟。

响应被返回给客户端后，Envoy 代理将收集原始的遥测数据。为请求收集原始遥测数据所花费的时间并没有统计在完成该请求所需的总时间里。但是，Worker 在忙着处理请求时是不会立刻开始处理下一个请求的。此过程会增加下一个请求的队列等待时间并影响平均延迟和尾部延迟。实际的尾部延迟取决于流量模式。

注意：在 Istio 1.7 版本中，我们通过在负载发生器中启用 `jitter`，来引入一种新的性能测量方式。它有助于在使用连接池时对来自客户端的随机流量进行建模。在下一节，我们将介绍 `jitter` 和 `non-jitter` 的性能测量。

### Istio {{< istio_release_name >}} 的延迟 {#latency-for-Istio}

在网格内部，一个请求会先遍历客户端代理，然后遍历服务端代理。Istio {{< istio_release_name >}} 的默认配置(即带有遥测功能的 Istio v2)，在 90% 的情况下，这两个代理在基线数据面延迟的基础上，分别增加了 2.65 毫秒和 2.91 毫秒的延迟。启用 `jitter` 后，这些数字分别减少 1.7 ms 和 2.69 ms。我们通过 `http/1.1` 协议的 [`Istio 基准测试`](https://github.com/istio/tools/tree/{{< source_branch_name >}}/perf/benchmark)获得了结果，测试标准是每秒 1000 请求，负载为 1KB，使用了 16 个客户端连接和 2 个代理，双向 TLS 打开状态。

{{< image width="90%"
    link="latency_p90_fortio_without_jitter.svg"
    alt="P90 latency vs client connections"
    caption="P90 latency vs client connections without jitter"
>}}

{{< image width="90%"
    link="latency_p99_fortio_without_jitter.svg"
    alt="P99 latency vs client connections"
    caption="P99 latency vs client connections without jitter"
>}}

{{< image width="90%"
    link="latency_p90_fortio_with_jitter.svg"
    alt="P90 latency vs client connections"
    caption="P90 latency vs client connections with jitter"
>}}

{{< image width="90%"
    link="latency_p99_fortio_with_jitter.svg"
    alt="P99 latency vs client connections"
    caption="P99 latency vs client connections with jitter"
>}}

- `baseline` 客户端 Pod 直接调用服务端 Pod，没有 Sidecar 参与。
- `none_both` Istio 代理，未配置 Istio 特定的过滤器。
- `v2-stats-wasm_both` 客户端和服务器 Sidecar 与遥测版本 v2 `v8`配置在一起。
- `v2-stats-nullvm_both` 默认情况下，客户端和服务器 Sidecar 与遥测版本 v2 `nullvm` 一起提供。
- `v2-sd-full-nullvm_both` 在配置了遥测 v2 `nullvm` 的情况下，导出 Stackdriver 指标、访问日志和边缘。
- `v2-sd-nologging-nullvm_both` 同上，但不导出访问日志。

### 基准测试工具 {#benchmarking-tools}

Istio 使用下面的工具进行基准测试：

- [`fortio.org`](https://fortio.org/) - 一个恒定的吞吐量负载测试工具。
- [`blueperf`](https://github.com/blueperf/) - 一个仿真云原生应用。
- [`isotope`](https://github.com/istio/tools/tree/{{< source_branch_name >}}/isotope) - 一个具有可配置拓扑结构的综合应用程序。

---
title: Istio 2020——为了商用
subtitle: Istio 2020 的目标是更快的速度，更简单的用法
description: Istio 在 2020 年的愿景声明及路线图。
publishdate: 2020-03-03
attribution: Istio Team
keywords: [roadmap,security,performance,operator]
---

Istio 解决了人们在运行微服务时遇到的实际问题。甚至[早期的预发行版本](https://kubernetespodcast.com/episode/016-descartes-labs/)就已经可以帮助用户诊断其体系架构中的延迟，提高服务的可靠性以及透明地保护防火墙后的流量。

去年，Istio 项目成长巨大。经过 9 个月的酝酿，在 2019 年第一季度发行 1.1 之前，我们设定了一个季度发布节奏的目标。我们知道，持续且可预测地交付非常重要。我们计划连续三个季度发布三个版本，并且我们为实现了这一目标感到自豪。

过去一年，我们改进了构建和测试基础架构，从而提高了质量并简化了发布周期。我们将用户体验提高了一倍，添加了许多命令使网格的操作和调试变得更加简单。我们还看到为 Istio 做出贡献的开发人员和公司数量急剧增长，最终，我们成为了 [GitHub 增长最快的十大项目中排名第 4 名](https://octoverse.github.com/#fastest-growing-oss-projects-by-contributors)！

2020 年，Istio 有宏伟的目标，并且我们正在努力中。与此同时，我们坚信良好的基础设施应该“无聊”。在生产中使用 Istio 应该是无缝的体验；性能不应该成为问题，升级应该是非事件性的，复杂的任务应自动化。随着我们对更强大的可扩展性的投入，我们认为 Istio 在专注于现在成就的同时，可以加快服务网格领域的创新步伐。以下是我们在 2020 年主要工作的详情。

## 更快、更简单{#sleeker-smoother-and-faster}

从第一天起，Istio 就通过 Mixer 组件提供了可扩展性支持。Mixer 是一个平台，允许使用自定义[适配器](/zh/docs/reference/config/policy-and-telemetry/mixer-overview/#adapters)充当数据平面与策略及遥测后端之间的中介。Mixer 必定会增加请求的开销，因为它必须扩展到进程之外。因此，我们正在向一种可以直接在代理中进行扩展的模型转变。

Istio 的[认证](/zh/docs/concepts/security/#authentication-policies)和[授权](/zh/docs/concepts/security/#authorization)策略已经涵盖了 Mixer 用于策略执行的大多数用例，这些策略使您可以直接在代理中控制 workload 到 workload 以及终端用户到 workload 的授权。常见的监控用例也已经转移到代理中，我们[引入了代理内支持](/zh/docs/ops/configuration/telemetry/in-proxy-service-telemetry/)，以便将遥测发送到 Prometheus 和 Stackdriver。

我们的基准测试表明，新的遥测模型可显著减少延迟，并可提供行业领先的性能，同时降低 50％ 的延迟和 CPU 消耗。

## 新的 Istio 可扩展性模型{#a-new-model-for-Istio-extensibility}

新的 Mixer 模型使用 Envoy 中的扩展来提供更多功能。Istio 社区正在领导 Envoy 的 [WebAssembly](https://webassembly.org/)（Wasm）运行时的实现，Wasm 让我们可以使用[超过 20 种的语言](https://github.com/appcypher/awesome-wasm-langs)来开发模块化、沙盒化的扩展。可以在代理继续提供流量的同时动态加载、重载扩展。Wasm 扩展程序还可以通过 Mixer 无法做到的方式来扩展平台。它们可以充当自定义协议处理程序，并在通过 Envoy 时转换有效负载，简而言之，它们可以执行与 Envoy 中内置的模块相同的操作。

我们正在与 Envoy 社区一起研究发现和分发这些扩展的方法。我们希望使 WebAssembly 扩展像容器一样易于安装和运行。我们的许多合作伙伴已经编写了 Mixer 适配器，并与我们一起将其移植到 Wasm。如何编写自己的扩展并进行自定义集成？我们正在开发相关的指南和代码实验室。

更换扩展模型后，我们还可以删除数十个 CRD。与 Istio 集成的每个软件都不再需要唯一 CRD。

通过 `preview` 配置文件安装 Istio 1.5 不会再安装 Mixer。安全起见，如果您是从以前的版本升级，或通过 `default` 配置文件安装，我们仍会保留 Mixer。当使用 Prometheus  或 Stackdriver 进行度量时，建议您尝试新模式并查看性能提高了多少。

如果有需要，您可以保持安装并启用 Mixer。最终，Mixer 将成为 Istio 单独的发行组件，成为 [istio-ecosystem](https://github.com/istio-ecosystem/) 的一部分。

## 减少移动部分{#fewer-moving-parts}

我们还将简化其余控制平面的 deployment。为此，我们将几个控制平面组件合并为一个组件：Istiod。该二进制文件包括 Pilot、Citadel、Galley 和 Sidecar 注入器的功能。这种方法从许多方面改善了 Istio 的安装和管理，降低了安装和配置的复杂性、维护工作量以及问题诊断时间，同时提高了响应速度。
关于 Istiod 的更多内容请查看 [Christian Posta 的这篇博客](https://blog.christianposta.com/microservices/istio-as-an-example-of-when-not-to-do-microservices/)。

我们将 Istiod 作为 1.5 中所有配置文件的默认配置。

为了减少每个节点的占用空间，我们放弃了用于分发证书的节点代理，并将其功能迁移至已经在每个 Pod 中运行的 istio-agent 中。从图片来看，我们正在从这里：

{{< image width="75%"
    link="./architecture-pre-istiod.svg"
    alt="基于 Pilot、Mixer、Citadel、Sidecar 注入器的 Istio 架构"
    caption="Istio 目前的架构"
    >}}

迁移到这里：

{{< image width="75%"
    link="./architecture-post-istiod.svg"
    alt="基于 Istiod 的 Istio 架构"
    caption="Istio 2020 年的架构"
    >}}

2020 年，我们将继续专注于普及，实现默认 `零配置` 的目标，该默认设置不需要您更改应用程序的任何配置即可使用 Istio 的大多数功能。

## 改进生命周期管理{#improved-lifecycle-management}

为了改进 Istio 的生命周期管理，我们使用了基于 [operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) 的安装方式。这里介绍 **[Istio Operator CRD 的两种安装模式](/zh/docs/setup/install/istioctl/)**：

- 人为触发：使用 istioctl 将设置应用至集群。
- 机器触发：使用一个控制器，实时观察 CRD 的改动并使其生效。

在 2020 年，升级 Istio 也将变得更加容易。我们将添加对 Istio 控制平面新版本的"金丝雀"支持，这使您可以同时运行现有版本的和新版本，并将数据平面逐渐切换至新版本。

## 默认安全{#secure-by-default}

Istio 已经为强大的服务安全性提供了基础：可靠的 workload 身份、强大的访问策略、全面的审核日志记录。我们正在为这些功能提供稳定的 API；许多 Alpha API 都将在 1.5 版中过渡为 Beta 版，我们希望到 2020 年底它们都将成为 v1 版本。要了解有关 API 状态的更多信息，请参见我们的[功能页面](/zh/about/feature-stages/#istio-features)。

默认情况下，网络流量也变得更加安全。继许多用户可以在评估时启用它之后，[自动双向 TLS](/zh/docs/tasks/security/authentication/auto-mtls/) 已成为 Istio 1.5 中的推荐做法。

此外，我们将让 Istio 所需的权限更少，并简化其依赖性，从而使 Istio 成为更强大的系统。在以前，您必须使用 Kubernetes Secrets 将证书安装到 Envoy，这些证书作为文件挂载至每个代理中。而现在，通过[密钥发现服务（SDS）](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret) ，我们可以安全地分发这些证书，而不必担心它们会被计算机上的其他 workload 拦截。该模式将成为 1.5 中的默认模式。

摆脱节点代理，不仅简化了部署，而且消除了对整个集群范围内 `PodSecurityPolicy` 的要求，从而进一步改善了集群的安全性。

## 其它功能{#other-features}

这是 Istio 在 2020 年一些值得期待的、令人兴奋的事情：

- 与更多托管的 Kubernetes 环境集成，目前已有 15 个供应商提供了 Istio 服务网格，这些公司包括：Google、IBM、Red Hat、VMware、Alibaba 以及 Huawei。
- 更多的关注 `istioctl` 及其帮助诊断问题的能力。
- 将基于 VM 的 workload 更好地集成到网格中。
- 继续努力使多群集和多网络网格更易于配置、维护和运行。
- 与更多的服务发现系统集成，包括 Functions-as-a-Service。
- 实现新的 [Kubernetes service API](https://kubernetes-sigs.github.io/service-apis/)（目前正在开发中）。
- [增强存储库](https://github.com/istio/enhancements/)，以便开发追踪功能。
- 让没有 Kubernetes 的 Istio 可以更轻松地运行！

从大海到[天空](https://www.youtube.com/watch?v=YjZ4AZ7hRM0)，Istio 期待您的加入！

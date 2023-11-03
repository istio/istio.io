---
title: "基于 Splunk 的全面网络安全"
description: "Istio 搭配其他工具确保 3 到 7 层网络安全。"
publishdate: 2023-04-03
attribution: "Bernard Van De Walle (Splunk), Mitch Connors (Aviatrix)"
keywords: [Istio,Security,Use Case]
---

市面上可用的网络安全保障工具种类非常丰富，也很容易找到这些独立工具的相关教程和演示，
这些工具可以为流量添加身份标识、策略和可观测性能力来使您的网络更加安全。
而通常较为不确定的是，这些工具如何在生产环境中相互作用为您的网络提供全面的安全性。
到底需要多少工具？具体什么时候可以认为您的网络已足够安全？

本文将探索使用 Splunk 来保护其管辖的 Kubernetes 网络基础设施用到的工具及其实践，
从 VPC 设计和连通性开始，到整个技术栈，直至基于 HTTP 请求的安全性。
在这个过程中，我们将了解如何为您的云原生技术栈提供全面的网络安全，
使用到的工具如何相互作用以及其中一些可改进的内容。在 Splunk
中使用多种工具来为其网络提供安全保障，包括：

* AWS 各项功能
* Kubernetes
* Istio
* Envoy
* Aviatrix

## 关于 Splunk 的使用场景 {#about-splunks-use-case}

Splunk 是一家提供用于收集、分析以及各类数据可视化平台的科技公司。
通过网页风格界面对机器生成的大量数据进行搜索、监控以及分析。
Splunk Cloud 是一项将 Splunk 内部基础架构迁移到云原生架构的计划。
如今，Splunk Cloud 由超过 35 个位于 AWS 和 GCP 遍布全球的完整集群副本组成。

## AWS、Aviatrix 和 Kubernetes 为 3/4 层提供安全保障 {#securing-layer-34-aws-aviatrix-and-kubernetes}

在 Splunk Cloud 中，我们使用一种被称为“cookie cutter VPCs”的模式，
为每个集群配备其自身的 VPC 网络，并且使 Pod 和节点 IP 具有相同的私有子网，
另外还提供进出公共互联网的公共子网，以及一个用于集群之间流量的内部子网。
这使来自不同集群的 Pod 和节点完全隔离，同时允许集群外部流量在公共和内部子网中强制执行特定规则。
此外，这种模式避免了在管理多个集群时 RFC 1918 专用 IP 耗尽的可能性。

在每个 VPC 中，Network ACL 和 Security Group 被设置为将连通性限制在绝对必需的范围内。
例如，我们将公开连通性限制在（将会部署 Envoy 入口网关的）Ingress 节点中。
除了普通的东西向和南北向流量外，Splunk 也提供每个集群都需要访问共享服务。
Aviatrix 用于提供重叠的 VPC 访问能力，同时还执行一些高级安全规则（按照域名进行分段）。

{{< image width="90%"
    link="CNCS 2023 - VPC Connectivity 3.png"
    caption="Splunk 网络安全架构"
    >}}

Splunk 技术栈中的下一个安全层级则是 Kubernetes 本身。用于验证功能的 Webhook
将防止某些 K8S 对象的部署，这些对象会允许集群中的不安全流量（通常围绕 NLB 和
Service）。Splunk 还依赖于 `NetworkPolicies` 来保护和限制 Pod 之间的连接。

## Istio 为 7 层提供安全保障 {#securing-layer-7-istio}

Splunk 使用 Istio 根据每个请求的详细信息在应用层执行相关策略。
Istio 也会发送 Telemetry 数据（指标、日志、跟踪），可用于验证请求级安全性。

Istio 注入 Envoy Sidecar 的其中一个主要优势是 Istio
可以为整个网格提供传输过程中的加密能力，而无需对应用程序进行任何修改。
应用程序只发送明文 HTTP 请求，但 Envoy Sidecar
拦截流量并实施双向 TLS 加密以防止劫持或篡改。

Istio 管理 Splunk 的入口网关，它接收来自公共和内部 NLB 的流量。
网关由平台团队管理并在 Istio Gateway 命名空间中运行，允许用户插拔，
但不能被用户修改。Gateway 服务还具备默认情况下强制执行 TLS 证书的能力，
用于验证的 Webhook 确保服务只能通过自身主机名连接到网关。此外，
在流量能够对应用程序 Pod 产生影响之前，网关会在入口强制对其执行请求身份验证。

由于 Istio 和相关的 K8S 对象配置起来相对复杂，所以 Splunk
创建了一个抽象层，它是一个可以为服务配置一切内容的控制器，包括：
VirtualService、DestinationRule、Gateway、证书等等。
它会将 DNS 直接写入正确的 NLB 中。它是用于端到端网络部署的一键式解决方案。
对于更复杂的场景，服务团队仍然可以绕过该抽象实现直接配置这些内容。

{{< image width="90%"
    link="Splunk Platform.png"
    caption="Splunk 应用平台"
    >}}

## 痛点 {#pain-points}

虽然 Splunk 的架构满足了我们的许多需求，但也有一些痛点值得讨论。
Istio 是通过创建与应用程序 Pod 数量相同的 Envoy Sidecar 模式运作的，
这是一种低效的资源使用方式。另外，当特定应用程序对其 Sidecar 有独特的需求时，
例如额外的 CPU 或内存，在不为网格中的所有 Sidecar 统一调整设置的情况下，
很难单独调整某个 Sidecar 的设置。Istio Sidecar 注入还涉及了很多魔法操作，
使用变异的 Webhook 在创建每个 Pod 时将 Sidecar 容器添加到应用程序 Pod 中，
意味着这些 Pod 将不再与其对应的部署定义匹配。此外，注入只能在 Pod 创建时发生，
这意味着无论何时更新 Sidecar 版本或参数，所有 Pod 都必须重新启动才能获得新设置。
总的来说，这种魔法使生产环境中运行服务网格变得复杂，并为您的应用程序增加了大量的不确定性操作。

Istio 项目也意识到了这些限制，并相信在新的 Istio Ambient 模式中，
这些限制将大大得到改善。在这种模式下，使用身份识别和加密等 Layer 4 能力，
将由运行在节点上的守护进程完成，而不会在与应用程序相同的 Pod 中进行。
Layer 7 功能仍将由 Envoy 处理，但 Envoy 将作为其自身部署的一部分在相邻的
Pod 中运行，而不是依赖于 Sidecar 注入的魔法操作。在 Ambient 模式下，应用程序
Pod 不会以任何方式被修改，这应该会为服务网格操作能力增加更多可预见性。
Ambient 模式有望在 Istio 1.18 中达到 Alpha 质量。

## 总结 {#conclusion}

有了 Splunk Cloud 网络安全的所有这些层级能力，
对于通过这些层级来退一步检查请求生命周期是非常有帮助的。当客户端发送请求时，
这些请求首先连接到 NLB，流量将由 `VPC ACL` 决定被允许或被阻止。然后 NLB
将请求代理到其中一个入口节点中，该节点将终止 TLS 并在 Layer 7 对请求进行检查，
并选择允许还是阻止该请求。接着，Envoy Gateway 使用 `ExtAuthZ`
验证请求以确保其身份的正确性，并在被允许进入集群之前满足配额限制。然后，Envoy Gateway
将请求代理到上游，来自 Kubernetes 的网络策略将再次确认该代理转发是否被允许。
上游工作负载上的 Sidecar 检查 Layer 7 请求，如果允许，
它将解密请求并将其以明文形式发送到工作负载。

{{< image width="90%"
    link="security matrix.png"
    caption="云原生网络安全矩阵"
    >}}

要在满足大型企业可扩展性需求的同时对 Splunk
云原生网络技术栈提供安全保障，需要在每一层级进行仔细的安全规划。

在技术栈中的每个层级都使用身份识别、可观测性和首选策略乍一看可能显得多余，
但是这样做的话，每个层级都能够弥补其他层级的缺点，
因此，这些层级联合形成了一个防止不必要访问的严密而有效的屏障。

如果您有兴趣深入了解 Splunk 的网络安全技术栈，可以观看我们的
Cloud Native SecurityCon [演讲](https://youtu.be/OuRQnJKIEaM)。

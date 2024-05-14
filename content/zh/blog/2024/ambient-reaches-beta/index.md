---
title: "Istio’s new sidecar-less ‘Ambient Mode’ reaches Beta in version 1.22 Istio 的新无 sidecar“Ambient 模式”在 1.22 版本中达到 Beta 版"
description: The latest release from Istio brings service mesh Layer 4 & 7 features to production readiness without sidecars. Istio 的最新版本将服务网格第 4 层和第 7 层功能带入生产就绪状态，无需 sidecar。
publishdate: 2024-05-13
attribution: "Lin Sun (Solo.io), for the Istio Steering and Technical Oversight Committees; Translated by Wilson Wu (DaoCloud)"
keywords: [Istio Day,Istio,conference,KubeCon,CloudNativeCon]
---

Istio ambient service mesh was [announced in September 2022](/blog/2022/introducing-ambient-mesh/) as an experimental branch that introduced a new data plane mode in Istio that did not require sidecars, offering a simplified operational experience of Istio. After 20 months of hard work and collaboration within the Istio community, with contributions from Solo.io, Google, Microsoft, Intel, Aviatrix, Huawei, IBM, Red Hat, and others, we are excited to announce that ambient mode has reached Beta in version 1.22! The beta release of 1.22 indicates the features of ambient mode are now ready for production workloads with appropriate precautions. This is a huge milestone for Istio, bringing both Layer 4 and Layer 7 mesh features to production readiness without sidecars.
Istio 环境服务网格[于 2022 年 9 月宣布](/blog/2022/introducing-ambient-mesh/) 作为一个实验分支，在 Istio 中引入了一种不需要 sidecar 的新数据平面模式，提供了 Istio 的简化操作体验 。 经过 Istio 社区 20 个月的努力和协作，在 Solo.io、Google、Microsoft、Intel、Aviatrix、华为、IBM、Red Hat 等公司的贡献下，我们很高兴地宣布环境模式已于 2019 年达到 Beta 版。 1.22版本！ 1.22 的测试版表明环境模式的功能现已准备好用于生产工作负载，并采取适当的预防措施。 这对于 Istio 来说是一个巨大的里程碑，将第 4 层和第 7 层网格功能带入生产状态，无需 sidecar。

## Why ambient mode?
## 为什么选择环境模式？

We listened to the feedback from Istio users and observed a growing demand for mesh capabilities for their applications but found the resource overhead and operational complexity of sidecars hard to overcome. Challenges that Istio sidecar users have shared with us include: how Istio can break applications after sidecars are added, the large consumption of resources by sidecars, and the inconvenience of the requirement to restart application pods with every new proxy release.
我们听取了 Istio 用户的反馈，并观察到他们的应用程序对网格功能的需求不断增长，但发现 sidecar 的资源开销和操作复杂性难以克服。 Istio sidecar 用户向我们分享的挑战包括：添加 sidecar 后 Istio 如何破坏应用程序、sidecar 对资源的大量消耗以及每次新代理发布时都需要重新启动应用程序 pod 带来的不便。

As a community, we listened and designed ambient mode to tackle these problems, alleviating the previous barriers of complexity faced by users looking to implement service mesh. This new feature from Istio was named 'ambient mode' as it was designed to be transparent to your application, ensuring no additional configuration was required to adopt it and required no restarting of applications by users. In ambient mode it is trivial to add or remove applications from the mesh. You can now simply label your namespace with `istio.io/dataplane-mode=ambient` and all applications in the namespace are added to the mesh. This immediately secures all traffic with mTLS, all without sidecars or the need to restart applications.
作为一个社区，我们倾听并设计了环境模式来解决这些问题，减轻了希望实现服务网格的用户之前面临的复杂性障碍。 Istio 的这一新功能被命名为“环境模式”，因为它的设计对您的应用程序是透明的，确保不需要额外的配置即可采用它，并且不需要用户重新启动应用程序。 在环境模式下，从网格中添加或删除应用程序很简单。 现在，您可以简单地使用“istio.io/dataplane-mode=ambient”标记您的命名空间，命名空间中的所有应用程序都会添加到网格中。 这会立即使用 mTLS 保护所有流量，并且无需 sidecar 或重新启动应用程序。

Refer to the [Introducing Ambient Mesh blog](/blog/2022/introducing-ambient-mesh/) for more information on why we started ambient mode in Istio.
请参阅[介绍环境网格博客](/blog/2022/introducing-ambient-mesh/)，了解有关我们为何在 Istio 中启动环境模式的更多信息。

## How does ambient mode make adoption easier?
## 环境模式如何让采用变得更容易？

Istio’s ambient mode introduces lightweight, shared node proxies and optional Layer 7 (L7) proxies, which removes the need for traditional sidecar proxies from the data plane. The core innovation behind ambient mode is that it slices the L4 and L7 processing into two distinct layers. This layered approach allows you to adopt Istio incrementally, enabling a smooth transition from no mesh, to a secure overlay (L4), to optional full L7 processing — on a per-namespace basis, as needed across your fleet.
Istio 的环境模式引入了轻量级共享节点代理和可选的第 7 层 (L7) 代理，从而消除了数据平面对传统 sidecar 代理的需求。 环境模式背后的核心创新在于它将 L4 和 L7 处理分为两个不同的层。 这种分层方法允许您逐步采用 Istio，实现从无网格到安全覆盖 (L4)，再到可选的完整 L7 处理的平滑过渡 - 根据整个队列的需要，在每个命名空间的基础上。

Ambient mode works without any modification required to your existing Kubernetes deployments. Users can label a namespace to add all of its workloads to Istio’s ambient mode, or opt-out certain deployments as needed. By utilizing ambient mode, users bypass some of the previously restrictive elements of the sidecar model and instead can now expect server send-first protocols to work, see most of the reserved ports are removed, and the ability for containers to bypass the sidecar – either maliciously or not – is eliminated.
环境模式无需对现有 Kubernetes 部署进行任何修改即可工作。 用户可以标记命名空间以将其所有工作负载添加到 Istio 的环境模式，或根据需要选择退出某些部署。 通过利用环境模式，用户绕过了 sidecar 模型中以前的一些限制性元素，现在可以期望服务器发送优先协议正常工作，看到大多数保留端口都被删除，并且容器能够绕过 sidecar – 或者 无论是否恶意——都会被消除。

The lightweight shared L4 node proxy is called ztunnel (zero-trust tunnel). Ztunnel drastically reduces the overhead of running a mesh by removing the need to potentially over provision memory and CPU within a cluster to handle expected loads. In some use cases, the savings can exceed 90% or more, while still providing zero-trust security using mutual TLS with cryptographic identity, simple L4 authorization policies, and telemetry.
轻量级共享L4节点代理称为ztunnel（零信任隧道）。 Ztunnel 无需在集群内过度配置内存和 CPU 来处理预期负载，从而大大降低了运行网格的开销。 在某些用例中，节省可以超过 90% 或更多，同时仍然使用具有加密身份的双向 TLS、简单的 L4 授权策略和遥测来提供零信任安全性。

The L7 proxies are called waypoints. Waypoints process L7 functions such as traffic routing, rich authorization policy enforcement, and enterprise-grade resilience. Waypoints run outside of your application deployments and can scale independently based on your needs, which could be for the entire namespace or for multiple services within the namespace. Compared with sidecars, you don’t need one waypoint per application pod, and you can scale your waypoint effectively based on its scope, thus saving significant amounts of CPU and memory in most cases.
L7 代理称为航路点。 Waypoints 处理 L7 功能，例如流量路由、丰富的授权策略实施和企业级弹性。 路点在应用程序部署之外运行，并且可以根据您的需求独立扩展，这可以针对整个命名空间或命名空间内的多个服务。 与 Sidecar 相比，每个应用程序 Pod 不需要一个路点，并且可以根据其范围有效地扩展路点，从而在大多数情况下节省大量 CPU 和内存。

The separation between the L4 secure overlay layer and L7 processing layer allows incremental adoption of the ambient mode data plane in contrast to the earlier binary "all-in" injection of sidecars. Users can start with the secure overlay layer which offers mTLS with cryptographic identity, simple L4 authorization policy, and telemetry. Later on, complex L7 handling such as retries, traffic splitting, complex load balancing, and observability collection can be enabled on a case-by-case basis.
L4 安全覆盖层和 L7 处理层之间的分离允许增量采用环境模式数据平面，这与早期的 sidecar 二进制“全输入”注入形成鲜明对比。 用户可以从安全覆盖层开始，该层提供具有加密身份的 mTLS、简单的 L4 授权策略和遥测。 稍后，可以根据具体情况启用复杂的 L7 处理，例如重试、流量分割、复杂的负载平衡和可观察性收集。

## What is in the scope of the Beta?
## Beta 版的范围包括哪些内容？

We recommend you explore the following Beta functions of ambient mode in production with appropriate precautions, after validating them in test environments:
我们建议您在测试环境中验证环境模式的以下 Beta 功能后，采取适当的预防措施，在生产中探索它们：

- [Install](/docs/ambient/install/).
- [Adding your workloads to the mesh](/docs/ambient/usage/add-workloads/) to gain mutual TLS with cryptographic identity, [L4 authorization policies](/docs/ambient/usage/l4-policy/), and telemetry.
- [Configure waypoints](/docs/ambient/usage/waypoint/) to [use L7 functions](/docs/ambient/usage/l7-features/) such as traffic shifting, request routing, rich authorization policy enforcement.
- Istio ingress gateway can work with workloads in ambient mesh supporting all existing Istio APIs.
- Use `istioctl` to operate waypoints, and troubleshoot ztunnel & waypoints.
- [安装](/docs/ambient/install/)。
- [将工作负载添加到网格中](/docs/ambient/usage/add-workloads/) 以获取具有加密身份的双向 TLS、[L4 授权策略](/docs/ambient/usage/l4-policy/) 以及 遥测。
- [配置路点](/docs/ambient/usage/waypoint/) [使用 L7 功能](/docs/ambient/usage/l7-features/)，例如流量转移、请求路由、丰富的授权策略实施。
- Istio 入口网关可以处理环境网格中的工作负载，支持所有现有的 Istio API。
- 使用 `istioctl` 操作航路点，并对 ztunnel 和航路点进行故障排除。

### Alpha features
### Alpha 功能

Other features we want to include in ambient mode have been implemented but remain in Alpha status in this release. Please help test them, so they can be promoted to Beta in 1.23 or later:
我们想要包含在环境模式中的其他功能已经实现，但在此版本中仍处于 Alpha 状态。 请帮助测试它们，以便它们可以在 1.23 或更高版本中升级为 Beta：

- Multi-cluster installations
- DNS proxying
- Interoperability with sidecars
- IPv6/Dual stack
- SOCKS5 support (for outbound)
- Istio’s classic APIs (`VirtualService` and `DestinationRule`)
- 多集群安装
- DNS 代理
- 与边车的互操作性
- IPv6/双栈
- SOCKS5 支持（用于出站）
- Istio 的经典 API（“VirtualService”和“DestinationRule”）

### Roadmap
### 路线图

We have a number of features which are not yet implemented in ambient mode but are planned for upcoming releases:
我们有许多功能尚未在环境模式下实现，但计划在即将发布的版本中实现：

- Controlled egress traffic
- Multi-network support
- Improve `status` messages on resources to help troubleshoot and understand the mesh
- VM support
- 受控的出口流量
- 多网络支持
- 改进资源上的“状态”消息，以帮助排除故障和了解网格
- 虚拟机支持

## What about sidecars?
## 边车怎么样？

Sidecars are not going away, and remain first-class citizens in Istio. You can continue to use sidecars and they will remain fully supported.  For any feature outside of the Alpha or Beta scope for ambient mode, you should consider using the sidecar mode until the feature is added to ambient mode. Some use cases, such as traffic shifting based on source labels, will continue to be best implemented using the sidecar mode. While we believe most use cases will be best served with a mesh in ambient mode, the Istio project remains committed to ongoing sidecar mode support.
Sidecar 不会消失，并且仍然是 Istio 中的一等公民。 您可以继续使用 sidecar，它们将保持完全支持。 对于环境模式的 Alpha 或 Beta 范围之外的任何功能，您应该考虑使用 sidecar 模式，直到该功能添加到环境模式。 一些用例，例如基于源标签的流量转移，将继续使用 sidecar 模式来最好地实现。 虽然我们相信大多数用例最好在环境模式下使用网格，但 Istio 项目仍然致力于持续支持 sidecar 模式。

## Try Istio’s new sidecar-less ambient mode
## 尝试 Istio 的新的无 sidecar 环境模式

With the 1.22 release of Istio and the beta release of ambient mode, it will be easier than ever to try out Istio on your own workloads. Follow the [getting started guide](/docs/ambient/getting-started/) to explore ambient or [user guide](/docs/ambient/usage/) to learn how to incrementally adopt ambient for mutual TLS & L4 authorization policy, traffic management, rich L7 authorization policy, and more. Engage with us in the #ambient channel on our [Slack](https://slack.istio.io) or our discussion forum on [GitHub](https://github.com/istio/istio/discussions) for any questions you may have.
随着 Istio 1.22 版本和环境模式 beta 版本的发布，在您自己的工作负载上尝试 Istio 将比以往更容易。 按照[入门指南](/docs/ambient/getting-started/) 探索环境或[用户指南](/docs/ambient/usage/) 了解如何逐步采用环境来实现双向 TLS 和 L4 授权策略， 流量管理、丰富的L7授权策略等等。 如有任何问题，请通过 [Slack](https://slack.istio.io) 上的 #ambient 频道或 [GitHub](https://github.com/istio/istio/discussions) 上的讨论论坛与我们联系 你可能有。

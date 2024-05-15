---
title: "Say goodbye to your sidecars: Istio's ambient mode reaches Beta in v1.22告别 Sidecar：Istio 的 Ambient 模式在 v1.22 中达到 Beta 版"
description: Layer 4 & Layer 7 features are both now ready for production.Layer 4 和 Layer 7 功能尚未针对生产环境做好准备。
publishdate: 2024-05-13
attribution: "Lin Sun (Solo.io)，代表 Istio 指导和技术监督委员会; Translated by Wilson Wu (DaoCloud)"
keywords: [ambient,sidecars]
---

Today, Istio's revolutionary new ambient {{< gloss >}}data plane{{< /gloss >}} mode has reached Beta. Ambient mode is designed for simplified operations, broader application compatibility, and reduced infrastructure cost. It gives you a sidecar-less data plane that’s integrated into your infrastructure, all while maintaining Istio’s core features of zero-trust security, telemetry, and traffic management.
今天，Istio 革命性的新 Ambient {{< gloss "data plane" >}}数据平面{{< /gloss >}}模式已达到 Beta 版。
Ambient 模式旨在简化操作、扩大应用程序兼容性并降低基础设施成本。
它为您提供了一个集成到您基础设施中的无 Sidecar 数据平面，
同时保留了 Istio 的零信任安全、遥测和流量管理的核心功能。

Ambient mode [was announced in September 2022](/blog/2022/introducing-ambient-mesh/). Since then, our community has put in 20 months of hard work and collaboration, with contributions from Solo.io, Google, Microsoft, Intel, Aviatrix, Huawei, IBM, Red Hat, and many others. Beta status in 1.22 indicates the features of ambient mode are now ready for production workloads, with appropriate precautions. This is a huge milestone for Istio, bringing both Layer 4 and Layer 7 mesh features to production readiness without sidecars.
Ambient 模式[于 2022 年 9 月宣布](/zh/blog/2022/introducing-ambient-mesh/)。
从那时起，我们的社区投入了 20 个月的辛勤工作和协作，其中包括 Solo.io、Google、Microsoft、Intel、Aviatrix、华为、IBM、Red Hat 和许多其他公司的贡献。
1.22 中的 Beta 状态表明 Ambient 模式的功能现已准备好用于生产工作负载，并采取适当的预防措施。
这对于 Istio 来说是一个巨大的里程碑，将 Layer 4 和 Layer 7 网格功能带入生产状态，无需 Sidecar。

## Why ambient mode?
## 为什么选择 Ambient 模式？ {#why-ambient-mode}

In listening to feedback from Istio users, we observed a growing demand for mesh capabilities for applications — but heard that many of you found the resource overhead and operational complexity of sidecars hard to overcome. Challenges that sidecar users shared with us include how Istio can break applications after sidecars are added, the large consumption of CPU and memory by sidecars, and the inconvenience of the requirement to restart application pods with every new proxy release.
在听取 Istio 用户的反馈时，我们发现应用程序对网格功能的需求不断增长，
但听说许多人发现 Sidecar 的资源开销和操作复杂性难以被克服。 
Sidecar 用户向我们分享的挑战包括添加 Sidecar 后 Istio 如何破坏应用程序、
Sidecar 对 CPU 和内存的大量消耗，以及每次新代理发布时都需要重新启动应用程序 Pod 带来的不便。

As a community, we designed ambient mode to tackle these problems, alleviating the previous barriers of complexity faced by users looking to implement service mesh. The new feature set was named 'ambient mode' as it was designed to be transparent to your application, ensuring no additional configuration was required to adopt it, and required no restarting of applications by users.
作为一个社区，我们设计了 Ambient 模式来解决这些问题，减轻了用户之前在实现服务网格时所面临的复杂性障碍。
新功能集被命名为 'ambient mode'（Ambient 模式），因为它被设计为对您的应用程序透明，
确保无需额外配置即可被采用，并且不需要用户重新启动应用程序。

In ambient mode it is trivial to add or remove applications from the mesh. You can now simply [label a namespace](/docs/ambient/usage/add-workloads/), and all applications in that namespace are added to the mesh. This immediately secures all traffic with mTLS, all without sidecars or the need to restart applications.
在 Ambient 模式下，从网格中添加或删除应用程序很简单。
现在，您可以简单地[标记命名空间](/zh/docs/ambient/usage/add-workloads/)，
该命名空间中的所有应用程序都会添加到网格中。这会立即使用 mTLS 保护所有流量，
并且无需 Sidecar 或重新启动应用程序。

Refer to the [Introducing Ambient Mesh blog](/blog/2022/introducing-ambient-mesh/) for more information on why we built ambient mode.
有关我们为何构建 Ambient 模式的更多信息，请参阅[Ambient 网格简介博客](/zh/blog/2022/introducing-ambient-mesh/)。

## How does ambient mode make adoption easier?
## Ambient 模式如何让使用变得更容易？ {#how-does-ambient-mode-make-adoption-easier}

Istio’s ambient mode introduces lightweight, shared Layer 4 (L4) node proxies and optional Layer 7 (L7) proxies, removing the need for traditional sidecar proxies from the data plane. The core innovation behind ambient mode is that it slices the L4 and L7 processing into two distinct layers. This layered approach allows you to adopt Istio incrementally, enabling a smooth transition from no mesh, to a secure overlay (L4), to optional full L7 processing — on a per-namespace basis, as needed, across your fleet.
Istio 的 Ambient 模式引入了轻量级、共享的 Layer 4（L4）节点代理和可选的 Layer 7（L7）代理，
从而消除了数据平面对传统 Sidecar 代理的需求。Ambient 模式背后的核心创新在于它将 L4 和 L7 处理分为两个不同的层。
这种分层方法允许您逐步采用 Istio，实现从无网格到安全覆盖（L4），
再到可选的完整 L7 处理的平滑过渡 - 在整个过程中基于每个命名空间根据需要采用。

Ambient mode works without any modification required to your existing Kubernetes deployments. You can label a namespace to add all of its workloads to the mesh, or opt-in certain deployments as needed. By utilizing ambient mode, users bypass some of the previously restrictive elements of the sidecar model. Server-send-first protocols now work, most reserved ports are now available, and the ability for containers to bypass the sidecar — either maliciously or not — is eliminated.
Ambient 模式无需对现有 Kubernetes 部署进行任何修改即可工作。
您可以标记命名空间以将其所有工作负载添加到网格中，或根据需要选择某些部署。
通过利用 Ambient 模式，用户可以绕过 Sidecar 模型之前的一些限制性元素。
服务器发送优先协议现在可以工作，大多数保留端口现在可用，
并且容器绕过 Sidecar 的能力（无论是恶意还是非恶意）都被消除了。

The lightweight shared L4 node proxy is called the *[ztunnel](/docs/ambient/overview/#ztunnel)* (zero-trust tunnel). Ztunnel drastically reduces the overhead of running a mesh by removing the need to potentially over-provision memory and CPU within a cluster to handle expected loads. In some use cases, the savings can exceed 90% or more, while still providing zero-trust security using mutual TLS with cryptographic identity, simple L4 authorization policies, and telemetry.
轻量级共享 L4 节点代理称为 **[ztunnel](/zh/docs/ambient/overview/#ztunnel)**（零信任隧道）。
ztunnel 无需在集群内过度配置内存和 CPU 来处理预期负载，从而大大降低了运行网格的开销。
在某些用例中，节省可以超过 90% 或更多资源，同时仍然使用具有加密身份的双向 TLS、
简单的 L4 鉴权策略和遥测来提供零信任安全性。

The L7 proxies are called *[waypoints](/docs/ambient/overview/#waypoint-proxies)*. Waypoints process L7 functions such as traffic routing, rich authorization policy enforcement, and enterprise-grade resilience. Waypoints run outside of your application deployments and can scale independently based on your needs, which could be for the entire namespace or for multiple services within a namespace. Compared with sidecars, you don’t need one waypoint per application pod, and you can scale your waypoint effectively based on its scope, thus saving significant amounts of CPU and memory in most cases.
L7 代理被称为 **[waypoint](/zh/docs/ambient/overview/#waypoint-proxies)**。
waypoint 处理 L7 功能，例如流量路由、丰富的鉴权策略实施和企业级弹性。
waypoint 在应用程序部署之外运行，并且可以根据您的需求独立扩展，这可以针对整个命名空间或命名空间内的多个服务。
与 Sidecar 相比，您不需要为每个应用程序 Pod 都配备一个 waypoint，
并且可以根据其范围有效地扩展 waypoint，从而在大多数情况下节省大量 CPU 和内存。

The separation between the L4 secure overlay layer and L7 processing layer allows incremental adoption of the ambient mode data plane, in contrast to the earlier binary "all-in" injection of sidecars. Users can start with the secure L4 overlay, which offers a majority of features that people deploy Istio for (mTLS, authorization policy, and telemetry). Complex L7 handling such as retries, traffic splitting, load balancing, and observability collection can then be enabled on a case-by-case basis.
L4 安全覆盖层和 L7 处理层之间的分离允许增量采用 Ambient 模式数据平面，
这与早期的 Sidecar 二进制“全量”注入形成鲜明对比。用户可以从安全的 L4 覆盖开始，
它提供了人们部署 Istio 的大部分功能（mTLS、鉴权策略和遥测）。
然后可以根据具体情况启用复杂的 L7 处理，例如重试、流量分割、负载均衡和可观察性收集。

## What is in the scope of the Beta?
## Beta 版范围都包含哪些内容？ {#what-is-in-the-scope-of-the-beta}

We recommend you explore the following Beta functions of ambient mode in production with appropriate precautions, after validating them in test environments:
我们建议您在测试环境中验证 Ambient 模式的以下 Beta 功能后，在生产中探索它们时采取适当的预防措施：

- [Installing Istio with support for ambient mode](/docs/ambient/install/).
- [安装支持 Ambient 模式的 Istio](/zh/docs/ambient/install/)。
- [Adding your workloads to the mesh](/docs/ambient/usage/add-workloads/) to gain mutual TLS with cryptographic identity, [L4 authorization policies](/docs/ambient/usage/l4-policy/), and telemetry.
- [将工作负载添加到网格中](/zh/docs/ambient/usage/add-workloads/)以获取具有加密身份的双向 TLS、
  [L4 鉴权策略](/zh/docs/ambient/usage/l4-policy/)以及遥测。
- [Configuring waypoints](/docs/ambient/usage/waypoint/) to [use L7 functions](/docs/ambient/usage/l7-features/) such as traffic shifting, request routing, and rich authorization policy enforcement.
- [配置 waypoint](/zh/docs/ambient/usage/waypoint/)
  [使用 L7 功能](/zh/docs/ambient/usage/l7-features/)，例如流量转移、请求路由和丰富的鉴权策略实施。
- Connecting the Istio ingress gateway to workloads in ambient mode, supporting all existing Istio APIs.
- 在 Ambient 模式下将 Istio 入口网关连接到工作负载，支持所有现有的 Istio API。
- Using `istioctl` to operate waypoints, and troubleshoot ztunnel & waypoints.
- 使用 `istioctl` 操作 waypoint，并对 ztunnel 和 waypoint 进行故障排查。

### Alpha features
### Alpha 阶段功能 {#alpha-features}

Many other features we want to include in ambient mode have been implemented, but remain in Alpha status in this release. Please help test them, so they can be promoted to Beta in 1.23 or later:
我们希望包含在 Ambient 模式中的许多其他功能已经实现，但在此版本中仍处于 Alpha 状态。
请帮助测试它们，以便它们可以在 1.23 或更高版本中升级为 Beta：

- Multi-cluster installations
- 多集群安装
- DNS proxying
- DNS 代理
- Interoperability with sidecars
- 与 Sidecar 的互操作性
- IPv6/Dual stack
- IPv6/双栈
- SOCKS5 support (for outbound)
- SOCKS5 支持（用于出站）
- Istio’s classic APIs (`VirtualService` and `DestinationRule`)
- Istio 的经典 API（`VirtualService` 和 `DestinationRule`）

### Roadmap
### 路线图 {#roadmap}

We have a number of features which are not yet implemented in ambient mode, but are planned for upcoming releases:
我们有许多功能尚未在 Ambient 模式下实现，但计划在即将发布的版本中实现：

- Controlled egress traffic
- 受控的出口流量
- Multi-network support
- 多网络支持
- Improve `status` messages on resources to help troubleshoot and understand the mesh
- 改进资源上的 `status` 消息，以帮助排除故障和了解网格
- VM support
- 虚拟机（VM）支持

## What about sidecars?
## Sidecar 将如何？ {#what-about-sidecars}

Sidecars are not going away, and remain first-class citizens in Istio. You can continue to use sidecars, and they will remain fully supported.  For any feature outside of the Alpha or Beta scope for ambient mode, you should consider using the sidecar mode until the feature is added to ambient mode. Some use cases, such as traffic shifting based on source labels, will continue to be best implemented using the sidecar mode. While we believe most use cases will be best served with a mesh in ambient mode, the Istio project remains committed to ongoing sidecar mode support.
Sidecar 不会消失，并且仍然是 Istio 的重中之重。您可以继续使用 Sidecar，它们将继续保持被完全支持。
对于 Ambient 模式的 Alpha 或 Beta 范围之外的任何功能，您应该考虑使用 Sidecar 模式，
直到该功能被添加到 Ambient 模式。一些用例，例如基于源标签的流量转移，将继续使用 Sidecar 模式来最好地实现。
虽然我们相信在网格中的大多数用例将被最好的在 Ambient 模式下支持，但 Istio 项目仍然致力于持续支持 Sidecar 模式。

## Try ambient mode today
## 马上尝试 Ambient 模式 {#try-ambient-mode-today}

With the 1.22 release of Istio and the Beta release of ambient mode, it is now easier than ever to try out Istio on your own workloads. Follow the [getting started guide](/docs/ambient/getting-started/) to explore ambient mode, or read our new [user guides](/docs/ambient/usage/) to learn how to incrementally adopt ambient for mutual TLS & L4 authorization policy, traffic management, rich L7 authorization policy, and more. You can engage with the developers in the #ambient channel on [the Istio Slack](https://slack.istio.io), or use the discussion forum on [GitHub](https://github.com/istio/istio/discussions) for any questions you may have.
随着 Istio 1.22 版本和 Ambient 模式 Beta 版本的发布，
现在在您自己的工作负载上尝试 Istio 比以往任何时候都更加容易。
按照[入门指南](/zh/docs/ambient/getting-started/)探索 Ambient 模式，
或阅读我们新的[用户指南](/zh/docs/ambient/usage/)了解如何逐步采用 Ambient 来实现双向 TLS & L4 鉴权策略、流量管理、丰富的 L7 鉴权策略等等。
您可以在 [Istio Slack](https://slack.istio.io) 上的 #ambient 频道与开发人员互动，
或使用 [GitHub](https://github.com/istio/istio) 上的讨论论坛解答您可能存在的任何问题。

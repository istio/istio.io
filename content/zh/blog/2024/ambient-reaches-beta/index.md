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

The lightweight shared L4 node proxy is called the *[ztunnel](/docs/ambient/overview/#ztunnel)* (zero-trust tunnel). Ztunnel drastically reduces the overhead of
running a mesh by removing the need to potentially over-provision memory and CPU within a cluster to handle expected loads. In
some use cases, the savings can exceed 90% or more, while still providing zero-trust security using mutual TLS with
cryptographic identity, simple L4 authorization policies, and telemetry.

The L7 proxies are called *[waypoints](/docs/ambient/overview/#waypoint-proxies)*. Waypoints process L7 functions such as traffic routing, rich authorization policy
enforcement, and enterprise-grade resilience. Waypoints run outside of your application deployments and can scale independently
based on your needs, which could be for the entire namespace or for multiple services within a namespace. Compared with
sidecars, you don’t need one waypoint per application pod, and you can scale your waypoint effectively based on its scope,
thus saving significant amounts of CPU and memory in most cases.

The separation between the L4 secure overlay layer and L7 processing layer allows incremental adoption of the ambient mode data
plane, in contrast to the earlier binary "all-in" injection of sidecars. Users can start with the secure L4 overlay, which
offers a majority of features that people deploy Istio for (mTLS, authorization policy, and telemetry).
Complex L7 handling such as retries, traffic splitting, load balancing, and observability collection can then be enabled on a case-by-case basis.

## What is in the scope of the Beta?

We recommend you explore the following Beta functions of ambient mode in production with appropriate precautions, after validating
them in test environments:

- [Installing Istio with support for ambient mode](/docs/ambient/install/).
- [Adding your workloads to the mesh](/docs/ambient/usage/add-workloads/) to gain mutual TLS with cryptographic identity, [L4 authorization policies](/docs/ambient/usage/l4-policy/), and telemetry.
- [Configuring waypoints](/docs/ambient/usage/waypoint/) to [use L7 functions](/docs/ambient/usage/l7-features/) such as traffic shifting, request routing, and rich authorization policy enforcement.
- Connecting the Istio ingress gateway to workloads in ambient mode, supporting all existing Istio APIs.
- Using `istioctl` to operate waypoints, and troubleshoot ztunnel & waypoints.

### Alpha features

Many other features we want to include in ambient mode have been implemented, but remain in Alpha status in this release. Please help
test them, so they can be promoted to Beta in 1.23 or later:

- Multi-cluster installations
- DNS proxying
- Interoperability with sidecars
- IPv6/Dual stack
- SOCKS5 support (for outbound)
- Istio’s classic APIs (`VirtualService` and `DestinationRule`)

### Roadmap

We have a number of features which are not yet implemented in ambient mode, but are planned for upcoming releases:

- Controlled egress traffic
- Multi-network support
- Improve `status` messages on resources to help troubleshoot and understand the mesh
- VM support

## What about sidecars?

Sidecars are not going away, and remain first-class citizens in Istio. You can continue to use sidecars, and they will remain
fully supported.  For any feature outside of the Alpha or Beta scope for ambient mode, you should consider using the sidecar
mode until the feature is added to ambient mode. Some use cases, such as traffic shifting based on source labels, will
continue to be best implemented using the sidecar mode. While we believe most use cases will be best served with a mesh in
ambient mode, the Istio project remains committed to ongoing sidecar mode support.

## Try ambient mode today

With the 1.22 release of Istio and the Beta release of ambient mode, it is now easier than ever to try out Istio on your own
workloads. Follow the [getting started guide](/docs/ambient/getting-started/) to explore ambient mode, or read our new [user guides](/docs/ambient/usage/)
to learn how to incrementally adopt ambient for mutual TLS & L4 authorization policy, traffic management, rich L7
authorization policy, and more. You can engage with the developers in the #ambient channel on [the Istio Slack](https://slack.istio.io),
or use the discussion forum on [GitHub](https://github.com/istio/istio/discussions) for any questions you may have.

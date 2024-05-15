---
title: "告别 Sidecar：Istio 的 Ambient 模式在 v1.22 中达到 Beta 版"
description: Layer 4 和 Layer 7 功能尚未针对生产环境做好准备。
publishdate: 2024-05-13
attribution: "Lin Sun (Solo.io)，代表 Istio 指导和技术监督委员会; Translated by Wilson Wu (DaoCloud)"
keywords: [ambient,sidecars]
---

今天，Istio 革命性的新 Ambient {{< gloss "data plane" >}}数据平面{{< /gloss >}}模式已达到 Beta 版。
Ambient 模式旨在简化操作、扩大应用程序兼容性并降低基础设施成本。
它为您提供了一个集成到您基础设施中的无 Sidecar 数据平面，
同时保留了 Istio 的零信任安全、遥测和流量管理的核心功能。

Ambient 模式[于 2022 年 9 月发布](/zh/blog/2022/introducing-ambient-mesh/)。
从那时起，我们的社区投入了 20 个月的辛勤工作和协作，其中包括 Solo.io、Google、Microsoft、Intel、Aviatrix、华为、IBM、Red Hat 和许多其他公司的贡献。
1.22 中的 Beta 状态表明 Ambient 模式的功能现已准备好用于生产工作负载，并采取适当的预防措施。
这对于 Istio 来说是一个巨大的里程碑，将 Layer 4 和 Layer 7 网格功能带入生产状态，无需 Sidecar。

## 为什么选择 Ambient 模式？ {#why-ambient-mode}

在听取 Istio 用户的反馈时，我们发现应用程序对网格功能的需求不断增长，
但听说许多人发现 Sidecar 的资源开销和操作复杂性难以被克服。
Sidecar 用户向我们分享的挑战包括添加 Sidecar 后 Istio 如何打破应用程序行为、
Sidecar 对 CPU 和内存的大量消耗，以及每次新代理发布时都需要重新启动应用程序 Pod 带来的不便。

作为一个社区，我们设计了 Ambient 模式来解决这些问题，减轻了用户之前在实现服务网格时所面临的复杂性障碍。
新功能集被命名为 'ambient mode'（Ambient 模式），因为它被设计为对您的应用程序透明，
确保无需额外配置即可被采用，并且不需要用户重新启动应用程序。

在 Ambient 模式下，从网格中添加或删除应用程序很简单。
现在，您可以简单地[标记命名空间](/zh/docs/ambient/usage/add-workloads/)，
该命名空间中的所有应用程序都会被添加到网格中。这会立即启用 mTLS 保护所有流量，
并且无需 Sidecar 或重新启动应用程序。

有关我们为何构建 Ambient 模式的更多信息，请参阅 [Ambient 网格简介博客](/zh/blog/2022/introducing-ambient-mesh/)。

## Ambient 模式如何让使用变得更容易？ {#how-does-ambient-mode-make-adoption-easier}

Istio 的 Ambient 模式引入了轻量级、共享的 Layer 4（L4）节点代理和可选的 Layer 7（L7）代理，
从而消除了数据平面对传统 Sidecar 代理的需求。Ambient 模式背后的核心创新在于它将 L4 和 L7 处理分为两个不同的层。
这种分层方法允许您逐步采用 Istio，实现从无网格到安全覆盖（L4），
再到可选的完整 L7 处理的平滑过渡 - 在整个过程中可基于每个命名空间根据需要采用。

Ambient 模式无需对现有 Kubernetes 部署进行任何修改即可工作。
您可以标记命名空间以将其所有工作负载添加到网格中，或根据需要选择某些部署。
通过利用 Ambient 模式，用户可以绕过 Sidecar 模型之前的一些限制性元素。
服务器发送优先协议现在可以工作，大多数保留端口现在可用，
并且容器绕过 Sidecar 的能力（无论是恶意还是非恶意）都被消除了。

轻量级共享 L4 节点代理被称为 **[ztunnel](/zh/docs/ambient/overview/#ztunnel)**（零信任隧道）。
ztunnel 无需在集群内过度配置内存和 CPU 来处理预期负载，从而大大降低了运行网格的开销。
在某些用例中，节省可以超过 90% 或更多资源，同时仍然使用具有加密身份的双向 TLS、
简单的 L4 鉴权策略和遥测来提供零信任安全性。

L7 代理被称为 **[waypoint](/zh/docs/ambient/overview/#waypoint-proxies)**。
waypoint 处理 L7 功能，例如流量路由、丰富的鉴权策略实施和企业级弹性。
waypoint 在应用程序部署之外运行，并且可以根据您的需求独立扩展，这可以针对整个命名空间或命名空间内的多个服务。
与 Sidecar 相比，您不需要为每个应用程序 Pod 都配备一个 waypoint，
并且可以根据其范围有效地扩展 waypoint，从而在大多数情况下节省大量 CPU 和内存。

L4 安全覆盖层和 L7 处理层之间的分离允许增量采用 Ambient 模式数据平面，
这与早期的 Sidecar 二进制“全量”注入形成鲜明对比。用户可以从安全的 L4 覆盖开始，
它提供了人们部署 Istio 的大部分功能（mTLS、鉴权策略和遥测）。
然后可以根据具体情况启用复杂的 L7 处理，例如重试、流量分割、负载均衡和可观察性收集。

## Beta 版范围都包含哪些内容？ {#what-is-in-the-scope-of-the-beta}

我们建议您在测试环境中验证 Ambient 模式的以下 Beta 功能后，在生产中探索它们时采取适当的预防措施：

- [安装支持 Ambient 模式的 Istio](/zh/docs/ambient/install/)。
- [将工作负载添加到网格中](/zh/docs/ambient/usage/add-workloads/)以获取具有加密身份的双向 TLS、
  [L4 鉴权策略](/zh/docs/ambient/usage/l4-policy/)以及遥测。
- [配置 waypoint](/zh/docs/ambient/usage/waypoint/)
  [使用 L7 功能](/zh/docs/ambient/usage/l7-features/)，例如流量转移、请求路由和丰富的鉴权策略实施。
- 在 Ambient 模式下将 Istio 入口网关连接到工作负载，支持所有现有的 Istio API。
- 使用 `istioctl` 操作 waypoint，并对 ztunnel 和 waypoint 进行故障排查。

### Alpha 阶段功能 {#alpha-features}

我们希望包含在 Ambient 模式中的许多其他功能已经被实现，但在此版本中仍处于 Alpha 状态。
请帮助测试它们，以便它们可以在 1.23 或更高版本中升级为 Beta：

- 多集群安装
- DNS 代理
- 与 Sidecar 的互操作性
- IPv6/双栈
- SOCKS5 支持（用于出站）
- Istio 的经典 API（`VirtualService` 和 `DestinationRule`）

### 路线图 {#roadmap}

我们有许多功能尚未在 Ambient 模式下实现，但计划在即将发布的版本中实现：

- 受控的出口流量
- 多网络支持
- 改进资源上的 `status` 消息，以帮助排除故障和了解网格
- 虚拟机（VM）支持

## Sidecar 将如何？ {#what-about-sidecars}

Sidecar 不会消失，并且仍然是 Istio 的重中之重。您可以继续使用 Sidecar，它们将继续保持被完全支持。
对于 Ambient 模式的 Alpha 或 Beta 范围之外的任何功能，您应该考虑使用 Sidecar 模式，
直到该功能被添加到 Ambient 模式中。一些用例，例如基于源标签的流量转移，将继续使用 Sidecar 模式来最好地实现。
虽然我们相信在网格中的大多数用例将被最好的在 Ambient 模式下支持，但 Istio 项目仍然致力于持续支持 Sidecar 模式。

## 马上尝试 Ambient 模式 {#try-ambient-mode-today}

随着 Istio 1.22 版本和 Ambient 模式 Beta 版本的发布，
现在在您自己的工作负载上尝试 Istio 比以往任何时候都更加容易。
按照[入门指南](/zh/docs/ambient/getting-started/)探索 Ambient 模式，
或阅读我们新的[用户指南](/zh/docs/ambient/usage/)了解如何逐步采用 Ambient 来实现双向 TLS & L4 鉴权策略、流量管理、丰富的 L7 鉴权策略等等。
您可以在 [Istio Slack](https://slack.istio.io) 上的 #ambient 频道与开发人员互动，
或使用 [GitHub](https://github.com/istio/istio) 上的讨论论坛解答您可能存在的任何问题。

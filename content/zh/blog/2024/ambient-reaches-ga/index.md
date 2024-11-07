---
title: "快速、安全且简单：Istio 的 Ambient 模式在 v1.24 中正式推出"
description: 我们最新发布的 Ambient 模式（无边车的服务网格）已为所有人做好准备。
publishdate: 2024-11-07
attribution: "Lin Sun (Solo.io)，代表 Istio 指导和技术监督委员会; Translated by Wilson Wu (DaoCloud)"
keywords: [ambient,sidecars]
---

我们很自豪地宣布，Istio 的 Ambient 数据平面模式已达到通用可用性（GA），
ztunnel、waypoint 和 API 已被 Istio TOC 标记为稳定。
这标志着 Istio [功能阶段进展](/zh/docs/releases/feature-stages/)的最后阶段，
表明 Ambient 模式已完全准备好用于广泛的生产用途。

Ambient 网格及其使用 Istio Ambient 模式的参考实现[于 2022 年 9 月发布](/zh/blog/2022/introducing-ambient-mesh/)。
从那时起，我们的社区已经投入了 26 个月的辛勤工作和协作，Solo.io、
谷歌、微软、英特尔、Aviatrix、华为、IBM、Red Hat 等许多公司都做出了贡献。
1.24 中的稳定状态表明 Ambient 模式的功能现已完全准备好用于广泛的生产工作负载。
这对 Istio 来说是一个巨大的里程碑，它使 Istio 无需 Sidecar 即可投入生产，
并[为用户提供了选择](/zh/docs/overview/dataplane-modes/)。

## 为什么是 Ambient 网格？ {#why-ambient-mesh}

自 2017 年 Istio 发布以来，我们观察到应用程序对网格功能的需求明显且不断增长 — 但听说许多用户发现
Sidecar 的资源开销和操作复杂性难以克服。Istio 用户与我们分享的挑战包括
Sidecar 在添加后如何破坏应用程序、每个工作负载的代理对 CPU 和内存的需求很大，
以及每次发布新的 Istio 版本时都需要重新启动应用程序 Pod 的不便。

作为一个社区，我们从头开始设计了 Ambient 网格来解决这些问题，
减轻了用户在实施服务网格时面临的先前复杂性障碍。这个新概念被命名为“Ambient 网格”，
因为它被设计为对您的应用程序透明，没有与用户工作负载共置的代理基础设施，
不需要对配置进行细微更改，也不需要重新启动应用程序。在 Ambient 模式下，
从网格中添加或删除应用程序非常简单。您需要做的就是[标记命名空间](/zh/docs/ambient/usage/add-workloads/)，
该命名空间中的所有应用程序都会立即添加到网格中。这会立即使用行业标准的双向 TLS
加密保护该命名空间内的所有流量 - 无需其他配置或重新启动！
有关我们构建 Istio Ambient 模式的原因的更多信息，
请参阅[介绍 Ambient 网格博客](/zh/blog/2022/introducing-ambient-mesh/)。

## Ambient 模式如何使采用变得更容易？ {#how-does-ambient-mode-make-adoption-easier}

Ambient 网格背后的核心创新是将四层 (L4) 和七层 (L7) 处理分为两个不同的层。
Istio 的 Ambient 模式由轻量级、共享的 L4 节点代理和可选的 L7 代理提供支持，
从数据平面上消除了对传统 Sidecar 代理的需求。这种分层方法允许您逐步采用 Istio，
从而实现从无网格到安全覆盖 (L4) 再到可选的完整 L7 处理的平稳过渡 — 根据需要，
按命名空间逐个进行，覆盖整个集群。

通过利用 Ambient 网格，用户可以绕过 Sidecar 模型中之前的一些限制元素。
服务器发送优先协议现在可行，大多数保留端口现在可用，
并且消除了容器绕过 Sidecar（无论是恶意的还是非恶意的）的能力。

轻量级共享 L4 节点代理称为 **[ztunnel](/zh/docs/ambient/overview/#ztunnel)**（零信任隧道）。
ztunnel 消除了在集群中过度配置内存和 CPU 以处理预期负载的需求，
从而大幅降低了运行网格的开销。在某些用例中，节省的成本可能超过 90% 或更多，
同时仍使用具有加密身份的相互 TLS、简单的 L4 授权策略和遥测提供零信任安全性。

L7 代理称为 **[waypoint](/zh/docs/ambient/overview/#waypoint-proxies)**。
waypoint 处理 L7 功能，例如流量路由、丰富的授权策略实施和企业级弹性。
waypoint 在您的应用程序部署之外运行，可以根据您的需求独立扩展，
可以是整个命名空间，也可以是命名空间内的多个服务。与 Sidecar 相比，
您不需要每个应用程序 Pod 一个 waypoint，并且您可以根据其范围有效地扩展 waypoint，
从而在大多数情况下节省大量 CPU 和内存。

L4 安全覆盖层与 L7 处理层之间的分离允许逐步采用环境模式数据平面，
这与早期的二进制“全部”注入 Sidecar 不同。用户可以从安全的 L4 覆盖开始，
它提供了人们部署 Istio 所需的大多数功能（mTLS、授权策略和遥测）。
然后可以根据具体情况启用复杂的 L7 处理，例如重试、流量拆分、负载均衡和可观察性收集。

## 快速探索和采用环境模式 {#rapid-exploration-and-adoption-of-ambient-mode}

Docker Hub 上的 ztunnel 镜像下载量已超过 [100 万次](https://hub.docker.com/search?q=istio)，
仅上周就有约 63,000 次下载。

{{< image width="100%"
    link="./ztunnel-image.png"
    alt="Docker Hub 中 Istio ztunnel 的下载量！"
    >}}

我们询问了一些用户对 Ambient 模式 GA 的看法：

{{< quote >}}
**Istio 通过其 Ambient 网格设计实现的服务网格对我们的 Kubernetes 集群来说是一个很好的补充，
它简化了团队职责和网格的整体网络架构。结合 Gateway API 项目，
它为我提供了一种很好的方法，使开发人员能够满足他们的网络需求，
同时只委托所需的控制。虽然这是一个快速发展的项目，但它在生产中一直很稳定可靠，
将成为我们在 Kubernetes 部署中实现网络控制的默认选项。**

— [Daniel Loader](https://uk.linkedin.com/in/danielloader)，Quotech 首席平台工程师
{{< /quote >}}

{{< quote >}}
**使用 Helm Chart 包装器安装 Ambient 网格非常简单。迁移就像设置 waypoint 网关、
更新命名空间上的标签和重新启动一样简单。我期待着放弃 Sidecar 并恢复资源。
此外，升级更容易。不再需要重新启动 Deployment！**

— [Raymond Wong](https://www.linkedin.com/in/raymond-wong-43baa8a2/)，福布斯高级架构师
{{< /quote >}}

{{< quote >}}
**Istio 的 Ambient 模式自 Beta 版以来一直服务于我们的生产系统。
我们对它的稳定性和简单性感到满意，并期待随着 GA 状态的到来，
它还能带来更多优势和功能。感谢 Istio 团队的不懈努力！**

— Saarko Eilers，EISST International Ltd 基础设施运营经理
{{< /quote >}}

{{< quote >}}
**通过在 Ambient 模式下从 AWS App Mesh 切换到 Istio，
我们仅通过删除 Sidecar 和 SPIRE 代理 DaemonSet 就能够削减大约 45% 的正在运行的容器。
我们获得了许多好处，例如降低与 Sidecar 相关的计算成本或可观察性成本，
消除与 Sidecar 启动和关闭相关的许多竞争条件，
以及仅通过迁移即可获得的所有开箱即用的好处，例如 mTLS、区域感知和工作负载负载平衡。**

— [Ahmad Al-Masry](https://www.linkedin.com/in/ahmad-al-masry-9ab90858/)，Harri DevSecOps 工程经理
{{< /quote >}}

{{< quote >}}
**我们之所以选择 Istio，是因为我们对 Ambient 网格感到兴奋。与其他选项不同，
使用 Istio，从 Sidecar 到无 Sidecar 的过渡并非是一次信念飞跃。
我们可以用 Istio 构建我们的服务网格基础设施，因为我们知道通往无 Sidecar 的道路是双向的。**

— [Troy Dai](https://www.linkedin.com/in/troydai/)，Coinbase 高级软件工程师
{{< /quote >}}

{{< quote >}}
**非常自豪地看到 Ambient 模式快速而稳定地发展到 GA，
以及过去几个月为实现这一目标而进行的所有令人惊叹的合作！我们期待着了解新架构将如何彻底改变电信世界。**

— [Faseela K](https://www.linkedin.com/in/faseela-k-42178528/)，爱立信云原生开发者
{{< /quote >}}

{{< quote >}}
**我们很高兴看到 Istio 数据平面随着环境模式的 GA 版本而发展，
并正在积极评估它是否适合我们的下一代基础设施平台。Istio 的社区充满活力且热情好客，
Ambient 网格证明了社区正在接受新想法并务实地努力改善开发人员大规模操作 Istio 的体验。**

— [Tyler Schade](https://www.linkedin.com/in/tylerschade/)，GEICO Tech 杰出工程师
{{< /quote >}}

{{< quote >}}
**随着 Istio 的 Ambient 模式正式发布，我们终于有了一个不依赖于 Pod 生命周期的服务网格解决方案，
解决了基于 Sidecar 的模型的主要限制。Ambient 网格提供了一种更轻量级、可扩展的架构，
通过消除 Sidecar 的资源开销，简化了操作并降低了我们的基础设施成本。**

— [Bartosz Sobieraj](https://www.linkedin.com/in/bartoszsobieraj/)，Spond 平台工程师
{{< /quote >}}

{{< quote >}}
**我们的团队之所以选择 Istio，是因为它的服务网格功能以及与 Gateway API 的紧密结合，
从而创建了一个基于 Kubernetes 的强大托管解决方案。在将应用程序集成到网格中时，
我们面临着 Sidecar 代理的资源挑战，这促使我们在 Beta 版中过渡到 Ambient 模式，
以提高可扩展性和安全性。我们从通过 ztunnel 实现的 L4 安全性和可观察性开始，
实现了集群内流量的自动加密和透明的流量监控。通过有选择地启用 L7 功能并将代理与应用程序分离，
我们实现了无缝扩展并降低了资源利用率和延迟。这种方法使开发人员能够专注于应用程序开发，
从而实现由 Ambient 模式支持的更具弹性、更安全、更可扩展的平台。**

— [Jose Marques](https://www.linkedin.com/in/jdcmarques/)，Blip.pt 高级 DevOps 工程师
{{< /quote >}}

{{< quote >}}
**我们正在使用 Istio 来确保网格中严格的 mTLS L4 流量，
我们对 Ambient 模式感到很兴奋。与 Sidecar 模式相比，它节省了大量资源，
同时使配置变得更加简单和透明。**

— [Andrea Dolfi](https://www.linkedin.com/in/andrea-dolfi-58b427128/)，DevOps 工程师
{{< /quote >}}

## 范围是什么？ {#what-is-in-scope}

Ambient 模式的普遍可用性意味着以下事项现在被认为是稳定的：

- [使用 Helm 或 `istioctl` 安装支持 Ambient 模式的 Istio](/zh/docs/ambient/install/)。
- [将工作负载添加到网格](/zh/docs/ambient/usage/add-workloads/)，
  以获得具有加密身份、[L4 鉴权策略](/zh/docs/ambient/usage/l4-policy/)和遥测的双向 TLS。
- [配置 waypoint](/zh/docs/ambient/usage/waypoint/)
  以[使用 L7 功能](/zh/docs/ambient/usage/l7-features/)，
  例如流量转移、请求路由和丰富的授权策略实施。
- 将 Istio 入口网关连接到 Ambient 模式下的工作负载，
  支持 Kubernetes Gateway API 和所有现有的 Istio API。
- 使用 waypoint 进行受控网格出口
- 使用 `istioctl` 操作 waypoint，并排除 ztunnel 和 waypoint 故障。

有关更多信息，请参阅[功能状态页面](/zh/docs/releases/feature-stages/#ambient-mode)。

### 路线图 {#roadmap}

我们不会止步不前！我们将继续为未来版本开发许多功能，包括目前处于 Alpha/Beta 阶段的一些功能。

在我们即将发布的版本中，我们希望快速实现以下 Ambient 模式的扩展：

- 全面支持 Sidecar 和 Ambient 模式互操作性
- 多集群安装
- 多网络支持
- VM 支持

## 那么 Sidecar 呢？ {#what-about-sidecars}

Sidecar 不会消失，它仍然是 Istio 的首选。您可以继续使用 Sidecar，
它们仍将得到全面支持。虽然我们认为大多数用例最适合使用 Ambient 模式下的网格，
但 Istio 项目仍致力于持续支持 Sidecar 模式。

## 今天尝试 Ambient 模式 {#try-ambient-mode-today}

随着 Istio 1.24 版本的发布和 Ambient 模式的 GA 版本的发布，
现在可以比以往更轻松地在您自己的工作负载上试用 Istio。

- 按照[入门指南](/zh/docs/ambient/getting-started/)探索 Ambient 模式。
- 阅读我们的[用户指南](/zh/docs/ambient/usage/)了解如何逐步采用 Ambient 模式来实现双向
  TLS 和 L4 鉴权策略、流量管理、丰富的 L7 鉴权策略等。
- 探索[新的 Kiali 2.0 仪表板](https://medium.com/kialiproject/kiali-2-0-for-istio-2087810f337e)以可视化您的网格。

您可以在 [Istio Slack](https://slack.istio.io) 上的 #ambient
频道与开发人员交流，或者使用 [GitHub](https://github.com/istio/istio/discussions)
上的讨论论坛来解答您的任何问题。

---
title: "趋于成熟的 Istio Ambient：与 Kubernetes 各供应商和各类 CNI 的兼容性"
description: 工作负载 Pod 和 ztunnel 之间的创新流量重定向机制。
publishdate: 2024-01-29
attribution: "Ben Leggett (Solo.io), Yuval Kohavi (Solo.io), Lin Sun (Solo.io); Translated by Wilson Wu (DaoCloud)"
keywords: [Ambient,Istio,CNI,ztunnel,traffic]
---

Istio 项目于 2022 年[宣布推出一种全新的无 Sidecar 数据平面模式：Ambient 网格](/zh/blog/2022/introducing-ambient-mesh/)，
并于 2023 年初[发布了 Alpha 版实现](/zh/news/releases/1.18.x/announcing-1.18/#ambient-mesh)。

Alpha 版的重点是在有限的配置和环境下证明 Ambient 数据平面模式的价值。
然而，当时的条件十分有限。Ambient 模式依赖于透明地重定向在工作负载 Pod 和
[ztunnel](/zh/blog/2023/rust-based-ztunnel/) 之间的流量，
然而，最初为此使用的机制与多种第三方容器网络接口（CNI）实现相冲突。
通过 GitHub Issue 和 Slack 的讨论，我们发现用户希望能够在
[minikube](https://github.com/istio/istio/issues/46163) 和
[Docker Desktop](https://github.com/istio/istio/issues/47436) 上使用 Ambient 模式，
希望使用 [Cilium](https://github.com/istio/istio/issues/44198)
和 [Calico](https://github.com/istio/istio/issues/40973) 等 CNI 实现，
还希望能够支持在 [OpenShift](https://github.com/istio/istio/issues/42341)
和 [Amazon EKS](https://github.com/istio/istio/issues/42340) 等使用内部 CNI 实现上运行的服务。
在各种场景下广泛支持 Kubernetes 已成为 Ambient 网格进阶至 Beta
的首要需求，也就是说人们期望 Istio 能够在任意 Kubernetes 平台和任何 CNI 实现中工作。
毕竟，如果 Ambient 不能随处可用，那么 Ambient 就不能被称为 Ambient！

在 Solo 公司，我们已将 Ambient 模式集成到 Gloo Mesh 产品中，
并针对这个难题提出了创新的解决方案。我们决定在
2023 年末将我们的修改提交到[上游](https://github.com/istio/istio/issues/48212)，
以帮助 Ambient 更快进阶至 Beta，让更多用户可以在 Istio 1.21 或更高版本中用上 Ambient，
并在他们各自的平台中体验 Ambient 这种无 Sidecar 网格的优势，不用再操心现有的 CNI 或首选的 CNI 是什么。

## 回首来时路，披荆斩棘 {#how-did-we-get-here}

### 服务网格和 CNI：错综复杂 {#service-meshes-and-cnis-its-complicated}

Istio 是一种服务网格，而所有服务网格严格意义上来说都不是
**CNI 实现** ，服务网格想要在所有 Kubernetes 集群运行，
底层需要一个[合规的主流 CNI 实现](https://www.cni.dev/docs/spec/#overview-1)。

这个主流 CNI 实现可能由您的云供应商（AKS、GKE 和 EKS 自己）提供，
也可能由 Calico 和 Cilium 等第三方 CNI 实现提供。
某些服务网格还可能捆绑了他们自己的主流 CNI 实现，他们明确要求只有这些实现才能让网格正常运行。

基本上，在使用 mTLS 保护 Pod 流量并在服务网格层应用高级身份验证和授权策略等操作之前，
您必须拥有一个具有功能性 CNI 实现的功能性 Kubernetes 集群，
以确保设置基本网络路径以便数据包可以从集群中的一个 Pod 发送到另一个 Pod（以及从一个节点发送到另一个节点）。

尽管某些服务网格也可能提供并需要自己的内部主流 CNI 实现，
而且有时可以在同一集群内并行运行两个主流 CNI 实现（例如，一个由云提供商提供，另一个由第三方实现），
但实际上，这会引入一系列兼容性问题、奇怪的行为、功能集减少以及由于每个
CNI 实现可能内部使用的机制差异而导致的一些不兼容性。

为了避免这些问题，Istio 项目选择不发布或要求我们自己的主流 CNI 实现，
甚至不需要“首选” CNI 实现 - 而是选择支持 CNI 链接与使用尽可能广泛的 CNI 实现生态系统，
并确保与托管产品、跨供应商支持以及与更广泛的 CNCF 生态系统的可组合性。

### Ambient Alpha 版中的流量重定向 {#traffic-redirection-in-ambient-alpha}

[istio-cni](/zh/docs/setup/additional-setup/cni/)
组件是 Sidecar 数据平面模式下的可选组件，
通常用于移除[对 `NET_ADMIN` 和 `NET_RAW` 功能的兼容性要求](/zh/docs/ops/deployment/requirements/)以供用户将 Pod 部署到网格中。
`istio-cni` 是 Ambient 数据平面模式中必需的组件。
`istio-cni` 组件**不是**主流 CNI 实现，它是一个节点代理，可以对集群中已存在的任何主流 CNI 实现进行扩展。

每当 Pod 被添加到 Ambient 网格时，`istio-cni` 组件都会为 Pod
和 Pod 所在节点中运行的 [ztunnel](/zh/blog/2023/rust-based-ztunnel/)
之间的所有传入和传出流量通过节点级网络命名空间配置流量重定向。
Sidecar 机制和 Ambient Alpha 版机制之间的主要区别在于，在后者中，
当 Pod 流量被重定向出 Pod 网络命名空间，并进入同位 ztunnel Pod
网络命名空间时 - 途中必然经过主机网络命名空间，这是实现此目标的批量流量重定向规则所在的地方。

当我们在多个具有自己的默认 CNI 的真实 Kubernetes 环境中进行更广泛的测试时，
很明显，在主机网络命名空间中捕获和重定向 Pod 流量（就像我们在 Alpha 版开发期间相同）无法满足我们的要求。
使用这种方法在这些不同的环境中以通用的方式实现我们的目标根本不可行。

在主机网络命名空间中重定向流量的根本问题在于，
这正是集群的主流 CNI 实现**必须**配置流量路由/网络规则的地方。
这造成了不可避免的冲突，最关键的是：

- 主流 CNI 实现的基本主机级网络配置可能会干扰 Istio 的 CNI
  扩展的主机级 Ambient 网络配置，从而导致流量中断和其他冲突。
- 如果用户部署了由主流 CNI 实现强制执行的网络策略，
  则在部署 Istio CNI 扩展时可能不会强制执行网络策略（取决于主流 CNI 实现如何执行 NetworkPolicy）

虽然我们可以根据具体情况针对**某些**主流 CNI 实现进行设计，
但我们无法可持续地实现通用 CNI 支持。我们考虑过 eBPF，
但意识到任何 eBPF 实现都会遇到相同的基本问题，
因为目前没有标准化的方法来安全地链接/扩展任意 eBPF 程序，
并且我们仍然很难用此方法支持非 eBPF CNI 实现。

### 应对挑战 {#addressing-the-challenges}

一个新的解决方案是必要的 - 在节点的网络命名空间中进行任何类型的重定向都会产生不可避免的冲突，
除非我们对兼容性需求进行妥协。

Sidecar 模式中，在 Sidecar 和应用程序 Pod 之间配置流量重定向很简单，
因为两者都在 Pod 的网络命名空间内运行。这让我灵光一现：为什么不模仿 Sidecar，
并在应用程序 Pod 的网络命名空间中配置重定向呢？

虽然这听起来只是一个“简单”的想法，但要如何让其实现呢？
Ambient 的一个关键要求是 ztunnel 必须在应用程序 Pod 外部的 Istio 系统命名空间中运行。
经过一番研究，我们发现在一个网络命名空间中运行的 Linux 进程可以在另一个网络命名空间中创建并拥有监听套接字。
这是 Linux 套接字 API 的基本功能。然而，为了使这项工作正常运行并覆盖所有 Pod 生命周期场景，
我们必须对 ztunnel 以及 `istio-cni` 节点代理进行架构变更。

在进行原型设计并充分验证这种新颖方法确实适用于我们可以访问的所有 Kubernetes 平台之后，
我们对这项工作建立了信心，并决定将这一新的工作负载 Pod 和 ztunnel 节点代理组件之间的 **in-Pod**
流量重定向机制模式贡献到上游，该机制是从头开始建立的，
与所有主流云提供商和 CNI 高度兼容。

关键的创新是将 Pod 的网络命名空间传递到同位的 ztunnel，
以便 ztunnel 可以在 Pod 的网络命名空间内部启动其重定向套接字，同时仍然在 Pod 外部运行。
通过这种方法，ztunnel 和应用程序 Pod 之间的流量重定向的方式与当今的 Sidecar 和应用程序 Pod 非常相似，
并且对于在节点网络命名空间中运行的任何 Kubernetes 主流 CNI 完全不可见。
网络策略可以继续由任何 Kubernetes 主流 CNI 执行和管理，
无论 CNI 是否使用 eBPF 或 iptables，都不会发生任何冲突。

## in-Pod 流量重定向的技术深入探讨 {#technical-deep-dive-of-in-pod-traffic-redirection}

首先，让我们回顾一下数据包是如何在 Kubernetes 中 Pod 之间传输的基础知识。

### Linux、Kubernetes 和 CNI - 什么是网络命名空间，为什么它很重要？ {#linux-kubernetes-and-cni----whats-a-network-namespace-and-why-does-it-matter}

在 Linux 中，**容器**是在隔离的 Linux 命名空间中运行的一个或多个 Linux 进程。
Linux 命名空间只是一个内核标志，用于控制在该命名空间内运行的进程能够看到的内容。
例如，如果您通过 `ip netns add my-linux-netns` 命令创建一个新的 Linux 网络命名空间并在其中运行一个进程，
则该进程只能看到在该网络命名空间中创建的网络规则。
它看不到在其外部创建的任何网络规则 - 即使该计算机上运行的所有内容仍然共享一个 Linux 网络堆栈。

Linux 命名空间在概念上很像 Kubernetes 命名空间 - 组织和隔离不同活动进程的逻辑标签，
并允许您创建关于给定命名空间内的事物可以看到的规则以及对它们应用什么规则 - 它们只是在更低的层次上运行。

当在网络命名空间内运行的进程创建向外发送其他内容的 TCP 数据包时，
该数据包必须首先由本地网络命名空间内的任何本地规则进行处理，
然后离开本地网络命名空间，传递到另一个网络命名空间。

例如，在没有安装任何网格的普通 Kubernetes 中，
一个 Pod 可能会创建一个数据包并将其发送到另一个 Pod，并且该数据包可能（取决于网络的设置方式）：
- 由源 Pod 的网络命名空间内的任何规则进行处理。
- 离开源 Pod 网络命名空间，并冒泡到节点的网络命名空间，并由该命名空间中的任何规则进行处理。
- 接着，最终被重定向到目标 Pod 的网络命名空间（并由那里的任何规则处理）。

在 Kubernetes 中，
[容器**运行时**接口（CRI）](https://kubernetes.io/zh-cn/docs/concepts/architecture/cri/)负责与 Linux 内核通信、
为新 Pod 创建网络命名空间并启动其中的流程。
然后，CRI 调用 [容器**网络**接口（CNI）](https://github.com/containernetworking/cni)，
该接口负责连接各个 Linux 网络命名空间中的网络规则，
以便数据包离开和进入新的 Pod 就可以到达他们应该去的地方。
对于 Kubernetes 或容器运行时来说，CNI 使用什么拓扑或机制来实现这一点并不重要 - 只要数据包到达它们应该在的地方，
Kubernetes 正常工作，所有人都高兴。

### 为什么我们放弃之前的模式？ {#why-did-we-drop-the-previous-model}

在 Istio Ambient 网格中，每个节点至少有两个作为 Kubernetes DaemonSet 运行的容器：
- 一个高效的 ztunnel，可作为网格流量代理职责和 L4 策略执行。
- 一个 `istio-cni` 节点代理，负责将新的和现有的 Pod 添加到 Ambient 网格中。

在之前的 Ambient 网格实现中，应用程序 Pod 被添加到 Ambient 网格的方式如下：
- `istio-cni` 节点代理检测现有或新启动的 Kubernetes Pod，
  其命名空间被标记为 `istio.io/dataplane-mode=ambient`，表明它应被包含在 Ambient 网格中。
- 然后，`istio-cni` 节点代理在主机网络命名空间中建立网络重定向规则，
  以便拦截进入或离开应用程序 Pod 的数据包，
  并将其重定向到相关代理[端口](https://github.com/istio/ztunnel/blob/master/ARCHITECTURE.md#ports)（15008、15006 或 15001）。

这意味着对于 Ambient 网格中 Pod 创建的数据包，该数据包将离开该源 Pod，
进入节点的主机网络命名空间，然后理想情况下会被拦截并重定向到该节点的 ztunnel（在其自己的网络命名空间中运行）
用于代理到目标 Pod，返回流程类似。

这个模式作为初始 Ambient 网格 Alpha 版实现的简易设计工作得很好，
但正如前面提到的，它有一个基本问题 - 具有许多 CNI 实现，并且在 Linux 中，
有许多根本不同且不兼容的方法，您可以使用在其中配置数据包的方式从一个网络名称空间到另一个网络名称空间。
您可以使用隧道、全覆盖网络、通过主机网络命名空间或绕过它。
您可以通过 Linux 用户空间网络堆栈进行数据包处理，也可以跳过它并在内核空间堆栈中来回传输数据包，等等。
对于每种可能的方法，也许都有一个 CNI 实现在使用它。

这意味着使用之前的重定向方法，有很多 CNI 实现根本无法与 Ambient 配合使用。
鉴于其对主机网络命名空间数据包重定向的依赖 - 任何不通过主机网络命名空间路由数据包的 CNI 都需要不同的重定向实现。
即使对于明确这样实现的 CNI，我们也会遇到不可避免且可能无法解决的主机级规则冲突问题。
我们是在 CNI 之前拦截，还是之后拦截？如果我们执行其中一项或另一项，
一些 CNI 是否会崩溃，而他们却没有预料到这一点？由于 NetworkPolicy 必须在主机网络命名空间中强制执行，
因此 NetworkPolicy 何时何地被强制执行？我们是否需要大量代码来对每个流行的 CNI 进行特殊处理？

### Istio Ambient 流量重定向：新模式 {#istio-ambient-traffic-redirection-the-new-model}

在新的 Ambient 模式中，应用程序 Pod 被添加到 Ambient 网格的方式如下：
- `istio-cni` 节点代理检测到一个 Kubernetes Pod（现有的或新启动的），
  其命名空间被标记为 `istio.io/dataplane-mode=ambient`，表明它应该包含在 Ambient 网格中。
  - 如果启动了一个应添加到 Ambient 网格中的**新** Pod，
    则 CRI 会触发 CNI 插件（由 `istio-cni` 代理安装和管理）。
    该插件用于将新的 Pod 事件推送到节点的 `istio-cni` 代理，
    并阻止 Pod 启动，直到代理成功配置重定向。由于 CNI 插件由 CRI 尽早在 Kubernetes Pod 创建过程中调用，
    这确保了我们可以足够早地建立流量重定向，以防止启动期间流量逃逸，而无需依赖初始化容器之类的机制。
  - 如果**已经运行**的 Pod 被添加到 Ambient 网格中，则会触发新的 Pod 事件。
    `istio-cni` 节点代理的 Kubernetes API 观察程序会检测到这一点，并以相同的方式配置重定向。
- `istio-cni` 节点代理进入 Pod 的网络命名空间，
  并在 Pod 网络命名空间内建立网络重定向规则，以便拦截进入和离开 Pod 的数据包，
  并将其透明地重定向到侦听[已知端口](https://github.com/istio/ztunnel/blob/master/ARCHITECTURE.md#ports)（15008、15006、15001）的节点本地 ztunnel 代理实例。
- 然后，`istio-cni` 节点代理通过 Unix 域套接字通知节点 ztunnel，
  它应该在 Pod 的网络命名空间内建立本地代理侦听端口
  （在 15008、15006 和 15001 上），并为 ztunnel 提供低等级 Linux
  [文件描述符](https://zh.wikipedia.org/wiki/File_descriptor)用来表示 Pod 的网络命名空间。
  - 虽然套接字通常是由实际在该网络命名空间内运行的进程在 Linux 网络命名空间内创建的，
    但完全可以利用 Linux 的低等级套接字 API 来允许在一个网络命名空间中运行的进程在另一个网络命名空间中创建侦听套接字，
    假设目标网络命名空间在创建时是已知的。
- 节点本地 ztunnel 在内部启动一个新的代理实例和侦听端口集，专用于新添加的 Pod。
- 一旦 in-Pod 重定向规则就位并且 ztunnel 建立完成侦听端口，
  Pod 就会被添加到网格中，并且流量开始像以前一样流经节点本地 ztunnel。

下面是显示应用程序 Pod 添加到 Ambient 网格的基本流程图：

{{< image width="100%"
    link="./pod-added-to-ambient.svg"
    alt="Pod 被添加到 Ambient 网格的流程"
    >}}

一旦 Pod 成功被添加到 Ambient 网格中，默认情况下，
进出网格中 Pod 的流量将像 Istio 一贯的做法一样使用 mTLS 完全加密。

现在，流量将作为加密流量进入和离开 Pod 网络命名空间 - 即使 Pod 中运行的用户应用程序对此一无所知，
看上去 Ambient 网格中的每个 Pod 都能够执行网格策略并安全地加密流量。

下图说明了新模式中 Ambient 网格中的 Pod 之间的加密流量如何流动：

{{< image width="100%"
    link="./traffic-flows-between-pods-in-ambient.svg"
    alt="HBONE 流量在 Ambient 网格中 Pod 之间的流程"
    >}}

而且，和以前一样，对于有必要的用例，仍然可以处理来自网格外部的未加密的明文流量并强制执行策略：

{{< image width="100%"
    link="./traffic-flows-plaintext.svg"
    alt="网格 Pod 之间的明文流量的流程"
    >}}

### 新的 Ambient 流量重定向：这给我们带来了什么 {#the-new-ambient-traffic-redirection-what-this-gets-us}

新 Ambient 捕获模式的最终结果是所有流量捕获和重定向都发生在 Pod 的网络命名空间内。
对于节点、CNI 和其他所有内容来说，Pod 内似乎有一个 Sidecar 代理，
即使 **Pod 中根本没有运行任何 Sidecar 代理**。请记住，CNI 实现的工作是将数据包**传入和传出** Pod。
根据设计和 CNI 规范，他们不关心在那之后数据包会发生什么。

这种方法会自动消除与各种 CNI 和 NetworkPolicy 实现的冲突，
并显着提高 Istio Ambient 网格与所有主流 CNI 中所有主流托管 Kubernetes 产品的兼容性。

## 总结 {#wrapping-up}

感谢我们可爱的社区在使用各种 Kubernetes 平台和 CNI 测试变更方面付出的巨大努力，
以及 Istio 维护人员的多轮审核，我们很高兴地宣布
[ztunnel](https://github.com/istio/ztunnel/pull/747)
和 [istio-cni](https://github.com/istio/istio/pull/48253)
实现此功能的 PR 已被合并到 Istio 1.21，并且默认为 Ambient 启用，
因此 Istio 用户可以开始在任何 Kubernetes 平台上使用 Istio 1.21 或更高版本中的任何 CNI 运行 Ambient 网格。
我们已经使用 GKE、AKS 和 EKS 及其提供的所有 CNI 实现，
还有 Calico 和 Cilium 等第三方 CNI 以及 OpenShift 等平台对此进行了测试，并取得了可靠的结果。

我们非常高兴能够通过 ztunnel 和用户应用程序 Pod 之间这种创新的 in-Pod 流量重定向方法，
推动 Istio Ambient 网格向前发展，使其能够在任何地方运行。
随着 Ambient Beta 版这一首要技术障碍的解决，我们迫不及待地与 Istio 社区的其他成员合作，
尽快将 Ambient 网格引入 Beta 版！要了解有关 Ambient 网格 Beta 版进度的更多信息，
请加入 Istio [slack](https://slack.istio.io) 中的 #ambient 和 #ambient-dev 频道，
或参加[每周三的 Ambient 贡献者会议](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings)，
或查看 Ambient 网格 Beta 版[项目板](https://github.com/orgs/istio/projects/9/views/3?filterQuery=beta)并帮助我们修复一些问题！

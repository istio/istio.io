---
title: "Maturing Istio Ambient: Compatibility Across Various Kubernetes Providers and CNIs 趋于成熟的 Istio Ambient：各类 Kubernetes 供应商和 CNI 之间的兼容性"
description: An innovative traffic redirection mechanism between workload pods and ztunnel.工作负载 Pod 和 ztunnel 之间的创新流量重定向机制。
publishdate: 2024-01-29
attribution: "Ben Leggett (Solo.io), Yuval Kohavi (Solo.io), Lin Sun (Solo.io); Translated by Wilson Wu (DaoCloud)"
keywords: [Ambient,Istio,CNI,ztunnel,traffic]
---

The Istio project [announced ambient mesh - its new sidecar-less dataplane mode](/blog/2022/introducing-ambient-mesh/) in 2022, and [released an alpha implementation](/news/releases/1.18.x/announcing-1.18/#ambient-mesh) in early 2023.
Istio 项目于 2022 年[宣布推出环境网格 - 其新的无 sidecar 数据平面模式](/blog/2022/introducing-ambient-mesh/)，并[发布了 alpha 实现](/news/releases/1.18.x/announcing -1.18/#ambient-mesh）于 2023 年初。

Our alpha was focused on proving out the value of the ambient data plane mode under limited configurations and environments. However, the conditions were quite limited. Ambient mode relies on transparently redirecting traffic between workload pods and [ztunnel](/blog/2023/rust-based-ztunnel/), and the initial mechanism we used to do that conflicted with several categories of 3rd-party Container Networking Interface (CNI) implementations. Through GitHub issues and Slack discussions, we heard our users wanted to be able to use ambient mode in [minikube](https://github.com/istio/istio/issues/46163) and [Docker Desktop](https://github.com/istio/istio/issues/47436), with CNI implementations like [Cilium](https://github.com/istio/istio/issues/44198) and [Calico](https://github.com/istio/istio/issues/40973), and on services that ship in-house CNI implementations like [OpenShift](https://github.com/istio/istio/issues/42341) and [Amazon EKS](https://github.com/istio/istio/issues/42340). Getting broad support for Kubernetes anywhere has become the No. 1 requirement for ambient mesh moving to beta — people have come to expect Istio to work on any Kubernetes platform and with any CNI implementation. After all, ambient wouldn’t be ambient without being all around you!
我们的阿尔法重点是在有限的配置和环境下证明环境数据平面模式的价值。 然而，当时的条件十分有限。 Ambient 模式依赖于透明地重定向工作负载 Pod 和 [ztunnel](/blog/2023/rust-based-ztunnel/) 之间的流量，而我们用来执行此操作的初始机制与多个类别的第 3 方容器网络接口 (CNI) ）实施。 通过 GitHub 问题和 Slack 讨论，我们听说我们的用户希望能够在 [minikube](https://github.com/istio/istio/issues/46163) 和 [Docker Desktop](https:// github.com/istio/istio/issues/47436），以及 CNI 实现，例如 [Cilium](https://github.com/istio/istio/issues/44198) 和 [Calico](https://github.com/ istio/istio/issues/40973)，以及提供内部 CNI 实现的服务，例如 [OpenShift](https://github.com/istio/istio/issues/42341) 和 [Amazon EKS](https:// github.com/istio/istio/issues/42340）。 在任何地方获得对 Kubernetes 的广泛支持已经成为环境网格转向 Beta 版的首要要求——人们开始期望 Istio 能够在任何 Kubernetes 平台和任何 CNI 实现上工作。 毕竟，如果周围环境不在你身边，那么环境就不再是环境了！

At Solo, we've been integrating ambient mode into our Gloo Mesh product, and came up with an innovative solution to this problem. We decided to [upstream](https://github.com/istio/istio/issues/48212) our changes in late 2023 to help ambient reach beta faster, so more users can operate ambient in Istio 1.21 or newer, and enjoy the benefits of ambient sidecar-less mesh in their platforms regardless of their existing or preferred CNI implementation.
在 Solo，我们一直在将环境模式集成到 Gloo Mesh 产品中，并针对这个问题提出了创新的解决方案。 我们决定在 2023 年末将我们的更改发布到[上游](https://github.com/istio/istio/issues/48212)，以帮助环境更快地达到 Beta 版，以便更多用户可以在 Istio 1.21 或更高版本中操作环境，并享受 无论其现有或首选的 CNI 实现如何，其平台中环境无 sidecar 网格的优势。

## How did we get here?
## 我们是如何到达这里的？

### Service meshes and CNIs: it's complicated
### 服务网格和 CNI：很复杂

Istio is a service mesh, and all service meshes by strict definition are not *CNI implementations* - service meshes require a [spec-compliant, primary CNI implementation](https://www.cni.dev/docs/spec/#overview-1) to be present in every Kubernetes cluster, and rest on top of that.
Istio 是一个服务网格，严格定义的所有服务网格都不是 *CNI 实现* - 服务网格需要 [符合规范的主要 CNI 实现](https://www.cni.dev/docs/spec/#overview -1) 存在于每个 Kubernetes 集群中，并以此为基础。

This primary CNI implementation may be provided by your cloud provider (AKS, GKE, and EKS all ship their own), or by third-party CNI implementations like Calico and Cilium. Some service meshes may also ship bundled with their own primary CNI implementation, which they explicitly require to function.
此主要 CNI 实现可能由您的云提供商（AKS、GKE 和 EKS 都自带）提供，也可能由 Calico 和 Cilium 等第三方 CNI 实现提供。 一些服务网格还可能与它们自己的主要 CNI 实现捆绑在一起，它们明确要求这些实现能够正常运行。

Basically, before you can do things like secure pod traffic with mTLS and apply high-level authentication and authorization policy at the service mesh layer, you must have a functional Kubernetes cluster with a functional CNI implementation, to make sure the basic networking pathways are set up so that packets can get from one pod to another (and from one node to another) in your cluster.
基本上，在使用 mTLS 保护 pod 流量并在服务网格层应用高级身份验证和授权策略等操作之前，您必须拥有一个具有功能性 CNI 实现的功能性 Kubernetes 集群，以确保设置基本网络路径 以便数据包可以从集群中的一个 Pod 发送到另一个 Pod（以及从一个节点发送到另一个节点）。

Though some service meshes may also ship and require their own in-house primary CNI implementation, and it is sometimes possible to run two primary CNI implementations in parallel within the same cluster (for instance, one shipped by the cloud provider, and a 3rd-party implementation), in practice this introduces a whole host of compatibility issues, strange behaviors, reduced feature sets, and some incompatibilities due to the wildly varying mechanisms each CNI implementation might employ internally.
尽管某些服务网格也可能提供并需要自己的内部主要 CNI 实现，但有时可以在同一集群内并行运行两个主要 CNI 实现（例如，一个由云提供商提供，另一个由第三个实现） 方实现），实际上，这会引入一系列兼容性问题、奇怪的行为、功能集减少以及由于每个 CNI 实现内部可能采用的机制差异很大而导致的一些不兼容性。

To avoid this, the Istio project has chosen not to ship or require our own primary CNI implementation, or even require a "preferred" CNI implementation - instead choosing to support CNI chaining with the widest possible ecosystem of CNI implementations, and ensuring maximum compatibility with managed offerings, cross-vendor support, and composability with the broader CNCF ecosystem.
为了避免这种情况，Istio 项目选择不发布或要求我们自己的主要 CNI 实现，甚至不需要“首选”CNI 实现 - 而是选择使用尽可能广泛的 CNI 实现生态系统来支持 CNI 链，并确保与 托管产品、跨供应商支持以及与更广泛的 CNCF 生态系统的可组合性。

### Traffic redirection in ambient alpha
### 环境 alpha 中的流量重定向

The [istio-cni](/docs/setup/additional-setup/cni/) component is an optional component in the sidecar data plane mode, commonly used to remove the [requirement for the `NET_ADMIN` and `NET_RAW` capabilities](/docs/ops/deployment/requirements/) for users deploying pods into the mesh. `istio-cni` is a required component in the ambient data plane mode.  The `istio-cni` component is _not_ a primary CNI implementation, it is a node agent that extends whatever primary CNI implementation is already present in the cluster.
[istio-cni](/docs/setup/additional-setup/cni/) 组件是 sidecar 数据平面模式下的可选组件，通常用于删除[对 `NET_ADMIN` 和 `NET_RAW` 功能的要求]( /docs/ops/deployment/requirements/) 供用户将 Pod 部署到网格中。 `istio-cni` 是环境数据平面模式中必需的组件。 “istio-cni”组件不是主要 CNI 实现，它是一个节点代理，可以扩展集群中已存在的任何主要 CNI 实现。

Whenever pods are added to an ambient mesh, the `istio-cni` component configures traffic redirection for all incoming and outgoing traffic between the pods and the [ztunnel](/blog/2023/rust-based-ztunnel/) running on the pod's node, via the node-level network namespace. The key difference between the sidecar mechanism and the ambient alpha mechanism is that in the latter, pod traffic was redirected out of the pod network namespace, and into the co-located ztunnel pod network namespace - necessarily passing through the host network namespace on the way, which is where the bulk of the traffic redirection rules to achieve this were implemented.
每当 Pod 添加到环境网格时，“istio-cni”组件都会为 Pod 和在 Pod 上运行的 [ztunnel](/blog/2023/rust-based-ztunnel/) 之间的所有传入和传出流量配置流量重定向。 节点，通过节点级网络命名空间。 sidecar 机制和环境 alpha 机制之间的主要区别在于，在后者中，pod 流量被重定向出 pod 网络命名空间，并进入同位 ztunnel pod 网络命名空间 - 途中必然经过主机网络命名空间 ，这是实现此目的的大部分流量重定向规则的实现位置。

As we tested more broadly in multiple real-world Kubernetes environments, which have their own default CNI, it became clear that capturing and redirecting pod traffic in the host network namespace, as we were during alpha development, was not going to meet our requirements. Achieving our goals in a generic manner across these diverse environments was simply not feasible with this approach.
当我们在多个具有自己的默认 CNI 的真实 Kubernetes 环境中进行更广泛的测试时，很明显，在主机网络命名空间中捕获和重定向 pod 流量（就像我们在 alpha 开发期间一样）无法满足我们的要求。 使用这种方法在这些不同的环境中以通用的方式实现我们的目标根本不可行。

The fundamental problem with redirecting traffic in the host network namespace is that this is precisely the same spot where the cluster's primary CNI implementation *must* configure traffic routing/networking rules. This created inevitable conflicts, most critically:
在主机网络命名空间中重定向流量的根本问题在于，这正是集群的主要 CNI 实现“必须”配置流量路由/网络规则的地方。 这造成了不可避免的冲突，最关键的是：

- The primary CNI implementation's basic host-level networking configuration could interfere with the host-level ambient networking configuration from Istio's CNI extension, causing traffic disruption and other conflicts.
- 主要 CNI 实现的基本主机级网络配置可能会干扰 Istio 的 CNI 扩展的主机级环境网络配置，从而导致流量中断和其他冲突。
- If users deployed a network policy to be enforced by the primary CNI implementation, the network policy might not be enforced when the Istio CNI extension is deployed (depending on how the primary CNI implementation enforces NetworkPolicy)
- 如果用户部署了由主 CNI 实现强制执行的网络策略，则在部署 Istio CNI 扩展时可能不会强制执行网络策略（取决于主 CNI 实现如何强制执行 NetworkPolicy）

While we could design around this on a case-by-case basis for _some_ primary CNI implementations, we could not sustainably approach universal CNI support. We considered eBPF, but realized any eBPF implementation would have the same basic problem, as there is no standardized way to safely chain/extend arbitrary eBPF programs at this time, and we would still potentially have a hard time supporting non-eBPF CNIs with this approach.
虽然我们可以根据具体情况针对某些主要 CNI 实现进行设计，但我们无法可持续地实现通用 CNI 支持。 我们考虑过 eBPF，但意识到任何 eBPF 实现都会遇到相同的基本问题，因为目前没有标准化的方法来安全地链接/扩展任意 eBPF 程序，并且我们仍然可能很难用此方法支持非 eBPF CNI 方法。

### Addressing the challenges
### 应对挑战

A new solution was necessary - doing redirection of any sort in the node's network namespace would create unavoidable conflicts, unless we compromised our compatibility requirements.
一个新的解决方案是必要的——在节点的网络命名空间中进行任何类型的重定向都会产生不可避免的冲突，除非我们妥协我们的兼容性要求。

In sidecar mode, it is trivial to configure traffic redirection between the sidecar and application pod, as both operate within the pod's network namespace. This led to a light-bulb moment: why not mimic sidecars, and configure the redirection in the application pod's network namespace?
在 sidecar 模式下，在 sidecar 和应用程序 Pod 之间配置流量重定向很简单，因为两者都在 Pod 的网络命名空间内运行。 这让我灵光一现：为什么不模仿 sidecar，并在应用程序 pod 的网络命名空间中配置重定向呢？

While this sounds like a "simple" thought, how would this even be possible? A critical requirement of ambient is that ztunnel must run outside application pods, in the Istio system namespace. After some research, we discovered a Linux process running in one network namespace could create and own listening sockets within another network namespace. This is a basic capability of the Linux socket API. However, to make this work operationally and cover all pod lifecycle scenarios, we had to make architectural changes to the ztunnel as well as to the `istio-cni` node agent.
虽然这听起来像是一个“简单”的想法，但这怎么可能呢？ ambient 的一个关键要求是 ztunnel 必须在应用程序 pod 外部的 Istio 系统命名空间中运行。 经过一番研究，我们发现在一个网络命名空间中运行的 Linux 进程可以在另一个网络命名空间中创建并拥有监听套接字。 这是 Linux 套接字 API 的基本功能。 然而，为了使这项工作正常运行并覆盖所有 Pod 生命周期场景，我们必须对 ztunnel 以及“istio-cni”节点代理进行架构更改。

After prototyping and sufficiently validating that this novel approach does work for all the Kubernetes platforms we have access to, we built confidence in the work and decided to contribute to upstream this new traffic redirection model, an *in-Pod* traffic redirection mechanism between workload pods and the ztunnel node proxy component that has been built from the ground up to be highly compatible with all major cloud providers and CNIs.
在进行原型设计并充分验证这种新颖方法确实适用于我们可以访问的所有 Kubernetes 平台之后，我们对这项工作建立了信心，并决定为这种新的流量重定向模型（工作负载之间的 *in-Pod* 流量重定向机制）的上游做出贡献。 Pod 和 ztunnel 节点代理组件从头开始构建，与所有主要云提供商和 CNI 高度兼容。

The key innovation is to deliver the pod’s network namespace to the co-located ztunnel so that ztunnel can start its redirection sockets _inside_ the pod’s network namespace, while still running outside the pod. With this approach, the traffic redirection between ztunnel and application pods happens in a way that’s very similar to sidecars and application pods today and is strictly invisible to any Kubernetes primary CNI operating in the node network namespace. Network policy can continue to be enforced and managed by any Kubernetes primary CNI, regardless of whether the CNI uses eBPF or iptables, without any conflict.
关键的创新是将 Pod 的网络命名空间传递到同位的 ztunnel，以便 ztunnel 可以在 Pod 的网络命名空间内部启动其重定向套接字，同时仍然在 Pod 外部运行。 通过这种方法，ztunnel 和应用程序 Pod 之间的流量重定向的方式与当今的 Sidecar 和应用程序 Pod 非常相似，并且对于在节点网络命名空间中运行的任何 Kubernetes 主 CNI 都是严格不可见的。 网络策略可以继续由任何 Kubernetes 主 CNI 执行和管理，无论 CNI 使用 eBPF 还是 iptables，都不会发生任何冲突。

## Technical deep dive of in-Pod traffic redirection
## Pod 内流量重定向的技术深入探讨

First, let’s go over the basics of how a packet travels between pods in Kubernetes.
首先，让我们回顾一下数据包如何在 Kubernetes 中的 Pod 之间传输的基础知识。

### Linux, Kubernetes, and CNI  - what’s a network namespace, and why does it matter?
### Linux、Kubernetes 和 CNI - 什么是网络命名空间，为什么它很重要？

In Linux, a *container* is one or more Linux processes running within isolated Linux namespaces. A Linux namespace is simply a kernel flag that controls what processes running within that namespace are able to see. For instance, if you create a new Linux network namespace via the `ip netns add my-linux-netns` command and run a process inside it, that process can only see the networking rules created within that network namespace. It can not see any network rules created outside of it - even though everything running on that machine is still sharing one Linux networking stack.
在 Linux 中，“容器”是在隔离的 Linux 命名空间中运行的一个或多个 Linux 进程。 Linux 命名空间只是一个内核标志，用于控制在该命名空间内运行的进程能够看到的内容。 例如，如果您通过“ip netns add my-linux-netns”命令创建一个新的 Linux 网络命名空间并在其中运行一个进程，则该进程只能看到在该网络命名空间中创建的网络规则。 它看不到在其外部创建的任何网络规则 - 即使该计算机上运行的所有内容仍然共享一个 Linux 网络堆栈。

Linux namespaces are conceptually a lot like Kubernetes namespaces - logical labels that organize and isolate different active processes, and allow you to create rules about what things within a given namespace can see and what rules are applied to them - they simply operate at a much lower level.
Linux 命名空间在概念上很像 Kubernetes 命名空间 - 组织和隔离不同活动进程的逻辑标签，并允许您创建关于给定命名空间内的事物可以看到的规则以及对它们应用什么规则 - 它们只是以低得多的速度运行 等级。

When a process running within a network namespace creates a TCP packet outward bound for something else, the packet must be processed by any local rules within the local network namespace first, then leave the local network namespace, passing into another one.
当在网络命名空间内运行的进程创建向外发送其他内容的 TCP 数据包时，该数据包必须首先由本地网络命名空间内的任何本地规则进行处理，然后离开本地网络命名空间，传递到另一个网络命名空间。

For example, in plain Kubernetes without any mesh installed, a pod might create a packet and send it to another pod, and the packet might (depending on how networking was set up):
例如，在没有安装任何网格的普通 Kubernetes 中，一个 Pod 可能会创建一个数据包并将其发送到另一个 Pod，并且该数据包可能（取决于网络的设置方式）：
- Be processed by any rules within the source pod’s network namespace.
- 由源 Pod 的网络命名空间内的任何规则进行处理。
- Leave the source pod network namespace, and bubble up into the node’s network namespace where it is processed by any rules in that namespace.
- 离开源 Pod 网络命名空间，并冒泡到节点的网络命名空间，并由该命名空间中的任何规则进行处理。
- From there, finally be redirected into the target pod’s network namespace (and processed by any rules there).
- 从那里，最终被重定向到目标 pod 的网络命名空间（并由那里的任何规则处理）。

In Kubernetes, the [Container *Runtime* Interface (CRI)](https://kubernetes.io/docs/concepts/architecture/cri/) is responsible for talking to the Linux kernel, creating network namespaces for new pods, and starting processes within them. The CRI then invokes the [Container *Networking* Interface (CNI)](https://github.com/containernetworking/cni), which is responsible for wiring up the networking rules in the various Linux network namespaces, so that packets leaving and entering the new pod can get where they’re supposed to go. It doesn’t matter much to Kubernetes or the container runtime what topology or mechanism the CNI uses to accomplish this - as long as packets get where they’re supposed to be, Kubernetes works and everyone is happy.
在 Kubernetes 中，[容器 *运行时* 接口 (CRI)](https://kubernetes.io/docs/concepts/architecture/cri/) 负责与 Linux 内核通信、为新 pod 创建网络命名空间并启动 其中的流程。 然后，CRI 调用 [Container *Networking* Interface (CNI)](https://github.com/containernetworking/cni)，该接口负责连接各个 Linux 网络命名空间中的网络规则，以便数据包离开和 进入新的吊舱就可以到达他们应该去的地方。 对于 Kubernetes 或容器运行时来说，CNI 使用什么拓扑或机制来实现这一点并不重要——只要数据包到达它们应该在的地方，Kubernetes 就能工作，每个人都高兴。

### Why did we drop the previous model?
### 为什么我们放弃之前的模型？

In Istio ambient mesh, every node has a minimum of two containers running as Kubernetes DaemonSets:
- An efficient ztunnel which handles mesh traffic proxying duties, and L4 policy enforcement.
- A `istio-cni` node agent that handles adding new and existing pods into the ambient mesh.
在 Istio 环境网格中，每个节点至少有两个作为 Kubernetes DaemonSet 运行的容器：
- 高效的 ztunnel，可处理网状流量代理职责和 L4 策略执行。
- 一个“istio-cni”节点代理，负责将新的和现有的 Pod 添加到环境网格中。

In the previous ambient mesh implementation, this is how application pod is added to the ambient mesh:
在之前的环境网格实现中，应用程序 pod 添加到环境网格的方式如下：
- The `istio-cni` node agent detects an existing or newly-started Kubernetes pod with its namespace labeled with `istio.io/dataplane-mode=ambient`, indicating that it should be included in the ambient mesh.
- `istio-cni` 节点代理检测现有或新启动的 Kubernetes pod，其命名空间标记为 `istio.io/dataplane-mode=ambient`，表明它应包含在环境网格中。
- The `istio-cni` node agent then establishes network redirection rules in the host network namespace, such that packets entering or leaving the application pod  would be intercepted and redirected to that node’s ztunnel on the relevant proxy [ports](https://github.com/istio/ztunnel/blob/master/ARCHITECTURE.md#ports) (15008, 15006, or 15001).
- 然后，`istio-cni` 节点代理在主机网络命名空间中建立网络重定向规则，以便拦截进入或离开应用程序 pod 的数据包，并将其重定向到相关代理 [端口](https:// github.com/istio/ztunnel/blob/master/ARCHITECTURE.md#ports）（15008、15006 或 15001）。

This means that for a packet created by a pod in the ambient mesh, that packet would leave that source pod, enter the node’s host network namespace, and then ideally would be intercepted and redirected to that node’s ztunnel (running in its own network namespace) for proxying to the destination pod, with the return trip being similar.
这意味着对于环境网格中的 pod 创建的数据包，该数据包将离开该源 pod，进入节点的主机网络命名空间，然后理想情况下会被拦截并重定向到该节点的 ztunnel（在其自己的网络命名空间中运行） 用于代理到目标 Pod，回程类似。

This model worked well enough as a placeholder for the initial ambient mesh alpha implementation, but as mentioned, it has a fundamental problem - there are many CNI implementations, and in Linux there are many fundamentally different and incompatible ways in which you can configure how packets get from one network namespace to another. You can use tunnels, overlay networks, go through the host network namespace, or bypass it. You can go through the Linux user space networking stack, or you can skip it and shuttle packets back and forth in the kernel space stack, etc. For every possible approach, there’s probably a CNI implementation out there that makes use of it.
这个模型作为初始环境网格 alpha 实现的占位符工作得很好，但正如前面提到的，它有一个基本问题 - 有许多 CNI 实现，并且在 Linux 中，有许多根本不同且不兼容的方法，您可以在其中配置数据包的方式 从一个网络名称空间到另一个网络名称空间。 您可以使用隧道、覆盖网络、通过主机网络命名空间或绕过它。 您可以浏览 Linux 用户空间网络堆栈，也可以跳过它并在内核空间堆栈中来回传输数据包，等等。对于每种可能的方法，可能都有一个利用它的 CNI 实现。

Which meant that with the previous redirection approach, there were a lot of CNI implementations ambient simply wouldn’t work with. Given its reliance on host network namespace packet redirection - any CNI that didn’t route packets thru the host network namespace would need a different redirection implementation. And even for CNIs that did do this, we would have unavoidable and potentially unresolvable problems with conflicting host-level rules. Do we intercept before the CNI, or after? Will some CNIs break if we do one, or the other, and they aren’t expecting that? Where and when is NetworkPolicy enforced, since NetworkPolicy must be enforced in the host network namespace? Do we need lots of code to special-case every popular CNI?
这意味着使用之前的重定向方法，有很多 CNI 实现环境根本无法使用。 鉴于其对主机网络命名空间数据包重定向的依赖 - 任何不通过主机网络命名空间路由数据包的 CNI 都需要不同的重定向实现。 即使对于确实这样做的 CNI，我们也会遇到不可避免且可能无法解决的主机级规则冲突问题。 我们是在 CNI 之前拦截，还是之后拦截？ 如果我们执行其中一项或另一项，一些 CNI 是否会崩溃，而他们却没有预料到这一点？ 由于 NetworkPolicy 必须在主机网络命名空间中强制执行，因此 NetworkPolicy 何时何地强制执行？ 我们是否需要大量代码来对每个流行的 CNI 进行特殊处理？

### Istio ambient traffic redirection: the new model
### Istio 环境流量重定向：新模型

In the new ambient model, this is how application pod is added to the ambient mesh:
在新的环境模型中，应用程序 pod 添加到环境网格的方式如下：
- The `istio-cni` node agent detects a Kubernetes pod (existing or newly-started) with its namespace labeled with `istio.io/dataplane-mode=ambient`, indicating that it should be included in the ambient mesh.
- `istio-cni` 节点代理检测到一个 Kubernetes pod（现有的或新启动的），其名称空间标记为 `istio.io/dataplane-mode=ambient`，表明它应该包含在环境网格中。
  - If a *new* pod is started that should be added to the ambient mesh, a CNI plugin (as installed and managed by the `istio-cni` agent) is triggered by the CRI. This plugin is used to push a new pod event to the node’s `istio-cni` agent, and block pod startup until the agent successfully configures redirection. Since CNI plugins are invoked by the CRI as early as possible in the Kubernetes pod creation process, this ensures that we can establish traffic redirection early enough to prevent traffic escaping during startup, without relying on things like init containers.
  - 如果启动了一个应添加到环境网格中的*新* pod，则 CRI 会触发 CNI 插件（由 `istio-cni` 代理安装和管理）。 该插件用于将新的 pod 事件推送到节点的“istio-cni”代理，并阻止 pod 启动，直到代理成功配置重定向。 由于 CNI 插件在 Kubernetes Pod 创建过程中尽早被 CRI 调用，这确保了我们可以尽早建立流量重定向，以防止启动期间流量逃逸，而无需依赖 init 容器之类的东西。
  - If an *already-running* pod becomes added to the ambient mesh, a new pod event is triggered. The `istio-cni` node agent’s Kubernetes API watcher detects this, and redirection is configured in the same manner.
  - 如果*已运行* Pod 添加到环境网格中，则会触发新的 Pod 事件。 `istio-cni` 节点代理的 Kubernetes API 观察程序会检测到这一点，并以相同的方式配置重定向。
- The `istio-cni` node agent enters the pod’s network namespace and establishes network redirection rules inside the pod network namespace, such that packets entering and leaving the pod are intercepted and transparently redirected to the node-local ztunnel proxy instance listening on [well-known ports](https://github.com/istio/ztunnel/blob/master/ARCHITECTURE.md#ports) (15008, 15006, 15001).
- `istio-cni` 节点代理进入 pod 的网络命名空间，并在 pod 网络命名空间内建立网络重定向规则，以便拦截进入和离开 pod 的数据包，并将其透明地重定向到侦听的节点本地 ztunnel 代理实例 -已知端口](https://github.com/istio/ztunnel/blob/master/ARCHITECTURE.md#ports) (15008、15006、15001)。
- The `istio-cni` node agent then informs the node ztunnel over a Unix domain socket that it should establish local proxy listening ports inside the pod’s network namespace, (on 15008, 15006, and 15001), and provides ztunnel with a low-level Linux [file descriptor](https://en.wikipedia.org/wiki/File_descriptor) representing the pod’s network namespace.
- 然后，“istio-cni”节点代理通过 Unix 域套接字通知节点 ztunnel，它应该在 pod 的网络命名空间内建立本地代理侦听端口（在 15008、15006 和 15001 上），并为 ztunnel 提供低- level Linux [文件描述符](https://en.wikipedia.org/wiki/File_descriptor) 表示 pod 的网络命名空间。
  - While typically sockets are created within a Linux network namespace by the process actually running inside that network namespace, it is perfectly possible to leverage Linux’s low-level socket API to allow a process running in one network namespace to create listening sockets in another network namespace, assuming the target network namespace is known at creation time.
  - 虽然套接字通常是由实际在该网络命名空间内运行的进程在 Linux 网络命名空间内创建的，但完全可以利用 Linux 的低级套接字 API 来允许在一个网络命名空间中运行的进程在另一个网络命名空间中创建侦听套接字 ，假设目标网络命名空间在创建时已知。
- The node-local ztunnel internally spins up a new proxy instance and listen port set, dedicated to the newly-added pod.
- 节点本地 ztunnel 在内部启动一个新的代理实例和侦听端口集，专用于新添加的 pod。
- Once the in-Pod redirect rules are in place and the ztunnel has established the listen ports, the pod is added in the mesh and traffic begins flowing thru the node-local ztunnel, as before.
- 一旦 Pod 内重定向规则到位并且 ztunnel 建立了侦听端口，Pod 就会添加到网格中，并且流量开始像以前一样流经节点本地 ztunnel。

Here’s a basic diagram showing the flow of application pod being added to the ambient mesh:
下面是显示应用程序 pod 添加到环境网格的流程的基本图：

{{< image width="100%"
    link="./pod-added-to-ambient.svg"
    alt="pod added to the ambient mesh flow"
    >}}
{{< image width="100%"
    link="./pod-added-to-ambient.svg"
    alt="Pod 添加到环境网格流中"
    >}}

Once the pod is successfully added to the ambient mesh, traffic to and from pods in the mesh will be fully encrypted with mTLS by default, as always with Istio.
一旦 pod 成功添加到环境网格中，默认情况下，进出网格中 pod 的流量将使用 mTLS 完全加密，就像 Istio 一贯的那样。

Traffic will now enter and leave the pod network namespace as encrypted traffic - it will look like every pod in the ambient mesh has the ability to enforce mesh policy and securely encrypt traffic, even though the user application running in the pod has no awareness of either.
现在，流量将作为加密流量进入和离开 pod 网络命名空间 - 看起来环境网格中的每个 pod 都能够执行网格策略并安全地加密流量，即使 pod 中运行的用户应用程序对此一无所知 。

Here’s a diagram to illustrate how encrypted traffic flows between pods in the ambient mesh in the new model:
下面的图表说明了新模型中环境网格中的 Pod 之间的加密流量如何流动：

{{< image width="100%"
    link="./traffic-flows-between-pods-in-ambient.svg"
    alt="HBONE traffic flows between pods in the ambient mesh"
    >}}
{{< image width="100%"
    link="./traffic-flows-between-pods-in-ambient.svg"
    alt="HBONE 流量在环境网格中的 Pod 之间流动"
    >}}

And, as before, unencrypted plaintext traffic from outside the mesh can still be handled and policy enforced, for use cases where that is necessary:
而且，和以前一样，对于有必要的用例，仍然可以处理来自网格外部的未加密的明文流量并强制执行策略：

{{< image width="100%"
    link="./traffic-flows-plaintext.svg"
    alt="Plain text traffic flow between meshed pods"
    >}}
{{< image width="100%"
    link="./traffic-flows-plaintext.svg"
    alt="网状 Pod 之间的纯文本流量"
    >}}

### The new ambient traffic redirection: what this gets us
### 新的环境流量重定向：这给我们带来了什么

The end result of the new ambient capture model is that all traffic capture and redirection happens inside the pod’s network namespace. To the node, the CNI, and everything else, it looks like there is a sidecar proxy inside the pod, even though there is **no sidecar proxy running in the pod** at all. Remember that the job of CNI implementations is to get packets **to and from** the pod. By design and by the CNI spec, they do not care what happens to packets after that point.
新环境捕获模型的最终结果是所有流量捕获和重定向都发生在 Pod 的网络命名空间内。 对于节点、CNI 和其他所有东西来说，Pod 内似乎有一个 Sidecar 代理，即使 Pod 中根本没有运行任何 Sidecar 代理。 请记住，CNI 实现的工作是从 Pod 中获取数据包。 根据设计和 CNI 规范，他们不关心在那之后数据包会发生什么。

This approach automatically eliminates conflicts with a wide range of CNI and NetworkPolicy implementations, and drastically improves Istio ambient mesh compatibility with all major managed Kubernetes offerings across all major CNIs.
这种方法会自动消除与各种 CNI 和 NetworkPolicy 实现的冲突，并显着提高 Istio 环境网格与所有主要 CNI 中所有主要托管 Kubernetes 产品的兼容性。

## Wrapping up
## 总结

Thanks to significant amounts of effort from our lovely community in testing the change with a large variety of Kubernetes platforms and CNIs, and many rounds of reviews from Istio maintainers, we are glad to announce that the [ztunnel](https://github.com/istio/ztunnel/pull/747) and [istio-cni](https://github.com/istio/istio/pull/48253) PRs implementing this feature merged to Istio 1.21 and are enabled by default for ambient, so Istio users can start running ambient mesh on any Kubernetes platforms with any CNIs in Istio 1.21 or newer. We’ve tested this with GKE, AKS, and EKS and all the CNI implementations they offer, as well as with 3rd-party CNIs like Calico and Cilium, as well as platforms like OpenShift, with solid results.
感谢我们可爱的社区在使用各种 Kubernetes 平台和 CNI 测试更改方面付出的巨大努力，以及 Istio 维护人员的多轮审核，我们很高兴地宣布 [ztunnel](https://github.com/ztunnel/ztunnel/ztunnel/ztunnel/ztunnel/ztunnel/ztunnel/ztunnel/ztunnel/ztunnel/ztunnel/ztunnel/ztunnel/ztunnel) com/istio/ztunnel/pull/747) 和 [istio-cni](https://github.com/istio/istio/pull/48253) 实现此功能的 PR 已合并到 Istio 1.21，并且默认为环境启用，因此 Istio 用户可以开始在任何 Kubernetes 平台上使用 Istio 1.21 或更高版本中的任何 CNI 运行环境网格。 我们已经使用 GKE、AKS 和 EKS 及其提供的所有 CNI 实现以及 Calico 和 Cilium 等第 3 方 CNI 以及 OpenShift 等平台对此进行了测试，并取得了可靠的结果。

We are extremely excited that we are able to move Istio ambient mesh forward to run everywhere with this innovative in-Pod traffic redirection approach between ztunnel and users’ application pods. With this top technical hurdle to ambient beta resolved, we can't wait to work with the rest of the Istio community to get ambient mesh to beta soon! To learn more about ambient mesh’s beta progress, join us in the #ambient and #ambient-dev channel in Istio’s [slack](https://slack.istio.io), or attend the [weekly ambient contributor meeting](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings) on Wednesdays, or check out the ambient mesh beta [project board](https://github.com/orgs/istio/projects/9/views/3?filterQuery=beta) and help us fix something!
我们非常高兴能够通过 ztunnel 和用户应用程序 Pod 之间这种创新的 Pod 内流量重定向方法，推动 Istio 环境网格向前运行，使其能够在任何地方运行。 随着环境 Beta 版这一首要技术障碍的解决，我们迫不及待地与 Istio 社区的其他成员合作，尽快将环境网格引入 Beta 版！ 要了解有关环境网格 Beta 版进度的更多信息，请加入 Istio [slack](https://slack.istio.io) 中的 #ambient 和 #ambient-dev 频道，或参加[每周环境贡献者会议](https: //github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings）周三，或查看环境网格测试版 [项目板](https://github.com/orgs /istio/projects/9/views/3?filterQuery=beta) 并帮助我们修复一些问题！

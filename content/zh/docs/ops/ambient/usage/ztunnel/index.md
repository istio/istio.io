---
title: ztunnel 中的 L4 网络与 mTLS  
description: 使用 ztunnel 代理的 Istio Ambient L4 网络和 mTLS 用户指南。
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

{{< warning >}}
`Ambient` 目前处于 [Alpha 状态](/zh/docs/releases/feature-stages/#feature-phase-definitions)。

Please **do not run ambient in production** and be sure to thoroughly review the [feature phase definitions](/docs/releases/feature-stages/#feature-phase-definitions) before use. In particular, there are known performance, stability, and security issues in the `alpha` release. There are also functional caveats some of which are listed in the [Caveats section](#caveats) of this guide. There are also planned breaking changes, including some that will prevent upgrades. These are all limitations that will be addressed before graduation to `beta`. The current version of this guide is meant to assist early deployments and testing of the alpha version of ambient. This guide will be updated as ambient itself evolves from alpha to beta status and beyond.
请**不要在生产环境中运行 Ambient**，
并确保在使用前彻底检查[功能阶段定义](/zh/docs/releases/feature-stages/#feature-phase-definitions)。
特别是，`alpha` 版本中存在已知的性能、稳定性和安全问题。
还有一些功能性注意事项，其中一些已在本指南的[注意事项部分](#caveats)中列出。
还有计划中的重大更改，包括一些会阻止升级的更改。这些都是在升级到 `beta`
之前将解决的所有限制。本指南的当前版本旨在帮助早期部署和测试 Ambient 的 Alpha 版本。
随着 Ambient 本身从 Alpha 状态发展到 Beta 及更高状态，本指南将随之进行更新。
{{< /warning >}}

## Introduction {#introsection}
## 简介  {#introsection}

This guide describes in-depth the functionality and usage of the ztunnel proxy and Layer-4 networking functions in Istio ambient mesh. To simply try out Istio ambient mesh, follow the [Ambient Quickstart](/docs/ops/ambient/getting-started/) instead. This guide follows a user journey and works through multiple examples to detail the design and architecture of Istio ambient. It is highly recommended to follow the topics linked below in sequence.
本指南深入介绍了 Istio Ambient 网格中 ztunnel 代理和 4 层网络能力的功能和用法。
要简单地尝试 Istio Ambient 网格，请按照
[Ambient 快速入门](/zh/docs/ops/ambient/getting-started/)进行操作。
本指南遵循用户旅程并通过多个示例来详细介绍 Istio Ambient 的设计和架构。
强烈建议按顺序关注下面链接的主题。

* [Introduction](#introsection)
* [Current Caveats](#caveats)
* [Functional Overview](#functionaloverview)
* [Deploying an Application](#deployapplication)
* [Monitoring the ztunnel proxy & L4 networking](#monitoringzt)
* [L4 Authorization Policy](#l4auth)
* [Ambient Interoperability with non-Ambient endpoints](#interop)
* [简介](#introsection)
* [当前注意事项](#caveats)
* [功能概述](#functionaloverview)
* [部署应用程序](#deployapplication)
* [监控 ztunnel 代理和 L4 网络](#monitoringzt)
* [L4 授权策略](#l4auth)
* [Ambient 与非 Ambient 端点的互操作性](#interop)

The ztunnel (Zero Trust Tunnel) component is a purpose-built per-node proxy for Istio ambient mesh. Since workload pods no longer require proxies running in sidecars in order to participate in the mesh, Istio in ambient mode is informally also referred to as "sidecar-less" mesh.
ztunnel（零信任隧道：Zero Trust Tunnel）组件是专门为 Istio Ambient 网格构建的基于每个节点的代理。
由于工作负载 Pod 不再需要在 Sidecar 中运行的代理也可以参与网格，
因此 Ambient 模式下的 Istio 也被非正式地称为“无 Sidecar”网格。

{{< tip >}}
Pods/workloads using sidecar proxies can co-exist within the same mesh as pods that operate in ambient mode. Mesh pods that use sidecar proxies can also interoperate with pods in the same Istio mesh that are running in ambient mode. The term ambient mesh refers to an Istio mesh that has a superset of the capabilities and hence can support mesh pods that use either type of proxying.
使用 Sidecar 代理的 Pod/工作负载可以与在 Ambient 模式下运行的 Pod 共存于同一网格内。
使用 Sidecar 代理的网格 Pod 还可以与同一 Istio 网格中以 Ambient 模式运行的 Pod 进行互操作。
Ambient 网格的概念是指具有功能超集的 Istio 网格，因此可以支持使用任一类型代理的网格 Pod。
{{< /tip >}}

The ztunnel node proxy is responsible for securely connecting and authenticating workloads within the ambient mesh. The ztunnel proxy is written in Rust and is intentionally scoped to handle L3 and L4 functions in the ambient mesh such as mTLS, authentication, L4 authorization and telemetry. Ztunnel does not terminate workload HTTP traffic or parse workload HTTP headers. The ztunnel ensures L3 and L4 traffic is efficiently and securely transported to **waypoint proxies**, where the full suite of Istio’s L7 functionality, such as HTTP telemetry and load balancing, is implemented. The term "Secure Overlay Networking" is used informally to collectively describe the set of L4 networking functions implemented in an ambient mesh via the ztunnel proxy. At the transport layer, this is implemented via an HTTP CONNECT-based traffic tunneling protocol called HBONE which is described in a [later section](#hbonesection) of this guide.
ztunnel 节点代理负责安全连接和验证 Ambient 网格内的工作负载。
ztunnel 代理是用 Rust 语言编写的，旨在处理 Ambient 网格中的 L3 和 L4 功能，
例如 mTLS、身份验证、L4 授权和遥测。ztunnel 不会终止工作负载 HTTP
流量或解析工作负载 HTTP 标头。ztunnel 确保 L3 和 L4 流量高效、安全地传输到 **waypoint 代理**，
其中实现了 Istio 的全套 L7 功能，例如 HTTP 遥测和负载均衡。
“安全覆盖网络（Secure Overlay Networking）”概念被非正式地用于统称通过
ztunnel 代理在 Ambient 网格中实现的 L4 网络功能集。
在传输层，这是通过称为 HBONE 的基于 HTTP CONNECT 的流量隧道协议来实现的，
该协议在本指南的[后续部分](#hbonesection)中进行了描述。

Some use cases of Istio in ambient mode may be addressed solely via the L4 secure overlay networking features, and will not need L7 features thereby not requiring deployment of a waypoint proxy. Other use cases requiring advanced traffic management and L7 networking features will require deployment of a waypoint proxy. This guide focuses on functionality related to the L4 secure overlay network using ztunnel proxies. This guide refers to L7 only when needed to describe some L4 ztunnel function. Other guides are dedicated to cover the advanced L7 networking functions and the use of waypoint proxies in detail.
Istio 在 Ambient 模式下的一些用例可以仅通过 L4 安全覆盖网络功能来解决，
并且不需要 L7 功能，因此不需要部署 waypoint 代理。
其他需要高级流量管理和 L7 网络功能的用例将需要部署 waypoint 代理。
本指南重点介绍与使用 ztunnel 代理的 L4 安全覆盖网络相关的功能。
本指南仅在需要描述某些 L4 ztunnel 功能时才引用 L7。
高级 L7 网络功能和 waypoint 代理的详细使用将在其他指南中专门介绍。

| Application Deployment Use Case | Istio Ambient Mesh Configuration |
| ------------- | ------------- |
| Zero Trust networking via mutual-TLS, encrypted and tunneled data transport of client application traffic, L4 authorization, L4 telemetry | Baseline Ambient Mesh with ztunnel proxy networking |
| Application requires L4 Mutual-TLS plus advanced Istio traffic management features (incl VirtualService, L7 telemetry, L7 Authorization) | Full Istio Ambient Mesh configuration both ztunnel proxy and waypoint proxy based networking |
| 应用程序部署用例 | Istio Ambient 网格配置 |
| ------------- | ------------- |
| 通过双向 TLS、客户端应用程序流量的加密和隧道数据传输、L4 授权、L4 遥测实现零信任网络 | 具有 ztunnel 代理网络的基线 Ambient 网格 |
| 应用程序需要 L4 Mutual-TLS 以及高级 Istio 流量管理功能（包括 VirtualService、L7 遥测、L7 授权） | 完整的 Istio Ambient 网格配置，包括基于 ztunnel 代理和 waypoint 代理的网络 |

## Current Caveats {#caveats}
## 当前注意事项  {#caveats}

Ztunnel proxies are automatically installed when one of the supported installation methods is used to install Istio ambient mesh. The minimum Istio version required for Istio ambient mode is `1.18.0`. In general Istio in ambient mode supports the existing Istio APIs that are supported in sidecar proxy mode. Since the ambient functionality is currently at an alpha release level, the following is a list of feature restrictions or caveats in the current release of Istio's ambient functionality (as of the `1.19.0` release). These restrictions are expected to be addressed/removed in future software releases as ambient graduates to beta and eventually General Availability.
当使用其中一种支持的安装方法安装 Istio Ambient 网格时，会自动安装 ztunnel 代理。
Istio Ambient 模式所需的最低 Istio 版本是 `1.18.0`。
一般来说，Ambient 模式下的 Istio 支持 Sidecar 代理模式下支持的现有 Istio API。
由于 Ambient 功能当前处于 Alpha 版本级别，
因此以下是 Istio Ambient 功能当前版本（自 `1.19.0` 版本起）中的功能限制或警告列表。
这些限制预计将在未来的软件版本中得到解决/删除，因为 Ambient 将进入 Beta 并最终正式发布。

1. **Kubernetes (K8s) only:** Istio in ambient mode is currently only supported for deployment on Kubernetes clusters. Deployment on non-Kubernetes endpoints such as virtual machines is not currently supported.
1. **仅限 Kubernetes（K8s）：**目前仅支持 Ambient 模式下的 Istio 在 Kubernetes 集群上部署。
   目前不支持在虚拟机等非 Kubernetes 端点上部署。

1. **No Istio multi-cluster support:** Only single cluster deployments are currently supported for Istio ambient mode.
1. **不支持 Istio 多集群：** Istio Ambient 模式当前仅支持单集群部署。

1. **K8s CNI restrictions:** Istio in ambient mode does not currently work with every Kubernetes CNI implementation. Additionally, with some plugins, certain CNI functions (in particular Kubernetes `NetworkPolicy` and Kubernetes Service Load balancing features) may get transparently bypassed in the presence of Istio ambient mode. The exact set of supported CNI plugins as well as any CNI feature caveats are currently under test and will be formally documented as Istio's ambient mode approaches the beta release.
1. **K8s CNI 限制：** Ambient 模式下的 Istio 目前不适用于所有 Kubernetes CNI 实现。
   此外，对于某些插件，某些 CNI 功能（特别是 Kubernetes `NetworkPolicy` 和 Kubernetes 服务负载均衡功能）
   可能会在 Istio Ambient 模式存在的情况下被透明绕过。
   已被支持的 CNI 插件的明确集合以及任何 CNI 功能警告目前正在测试中，
   并将在 Istio Ambient 模式接近 Beta 版本时正式提供文档。

1. **TCP/IPv4 only:** In the current release, TCP over IPv4 is the only protocol supported for transport on an Istio secure overlay tunnel (this includes protocols such as HTTP that run between application layer endpoints on top of the TCP/ IPv4 connection).
1. **仅限 TCP/IPv4：**在当前版本中，基于 IPv4 的 TCP 是
   Istio 安全覆盖隧道上唯一支持的传输协议（这包括在 TCP/IPv4 连接之上的应用程序层端点之间运行的 HTTP 等协议）。

1. **No dynamic switching to ambient mode:** ambient mode can only be enabled on a new Istio mesh control plane that is deployed using ambient profile or ambient helm configuration. An existing Istio mesh deployed using a pre-ambient profile for instance can not be dynamically switched to also enable ambient mode operation.
1. **无法动态切换到 Ambient 模式：**Ambient 模式只能在使用 Ambient 配置文件或
   Ambient Helm 配置部署的新 Istio 网格控制平面上启用。
   例如，使用 Pre-Ambient 配置文件部署的现有 Istio 网格无法被动态切换至同时启用 Ambient 模式的状态。

1. **Restrictions with Istio `PeerAuthentication`:** as of the time of writing, the `PeerAuthentication` resource is not supported by all components (i.e. waypoint proxies) in Istio ambient mode. Hence it is recommended to only use the `STRICT` mTLS mode currently. Like many of the other alpha stage caveats, this shall be addressed as the feature moves toward beta status.
1. **Istio `PeerAuthentication` 的限制：**截至撰写本文时，Istio Ambient 模式下的所有组件（即 waypoint 代理）
   并不支持 `PeerAuthentication` 资源。因此，建议当前仅使用 `STRICT` mTLS 模式。
   与许多其他 Alpha 阶段的注意事项一样，随着该功能转向 Beta 状态，该问题应该会得到解决。

1. **istioctl CLI gaps:** There may be some minor functional gaps in areas such as Istio CLI output displays when it comes to displaying or monitoring Istio's ambient mode related information. These will be addressed as the feature matures.
1. **istioctl CLI 差距：**在显示或监控 Istio Ambient 模式相关信息时，
   Istio CLI 输出显示等区域可能存在一些细微的功能差距。随着功能的成熟，这些问题将得到解决。

### Environment used for this guide
### 本指南使用的环境  {#environment-used-for-this-guide}

The examples in this guide used a deployment of Istio version `1.19.0` on a `kind` cluster of version `0.20.0` running Kubernetes version `1.27.3`.
本指南中的示例运行在基于 `kind` `0.20.0` 版的
Kubernetes `1.27.3` 集群的 Istio `1.19.0` 版本中。

The minimum Istio version needed for ambient functions is 1.18.0 and the minimum Kubernetes version needed is `1.24.0`. The examples below require a cluster with more than 1 worker node in order to explain how cross-node traffic operates. Refer to the [installation user guide](/docs/ops/ambient/usage/install/) or [getting started guide](/docs/ops/ambient/getting-started/) for information on installing Istio in ambient mode on a Kubernetes cluster.
Ambient 功能所需的最低 Istio 版本是 1.18.0，所需的最低 Kubernetes 版本是 `1.24.0`。
下面的示例需要一个具有超过 1 个工作节点的集群，以便解释跨节点流量的运行方式。
请参阅[安装用户指南](/zh/docs/ops/ambient/usage/install/)或[入门指南](/zh/docs/ops/ambient/getting-started/)，
了解关于在 Kubernetes 集群中安装 Ambient 模式 Istio 的信息。

## Functional Overview {#functionaloverview}
## 功能概述  {#functionaloverview}

The functional behavior of the ztunnel proxy can be divided into its data plane behavior and its interaction with the Istio control plane. This section takes a brief look at these two aspects - detailed description of the internal design of the ztunnel proxy is out of scope for this guide.
ztunnel 代理的功能行为可以分为数据平面行为和与 Istio 控制平面的交互。
本节简要介绍这两个方面 - ztunnel 代理内部设计的详细描述超出了本指南的范围。

### Control plane overview
### 控制平面概述  {#control-plane-overview}

The figure shows an overview of the control plane related components and flows between ztunnel proxy and the `istiod` control plane.
该图展示了 ztunnel 代理和 `istiod` 控制平面以及控制平面相关组件之间的流程概述。

{{< image width="100%"
link="ztunnel-architecture.png"
caption="Ztunnel architecture"
>}}
{{< image width="100%"
link="ztunnel-architecture.png"
caption="ztunnel 架构"
>}}

The ztunnel proxy uses xDS APIs to communicate with the Istio control plane (`istiod`). This enables the fast, dynamic configuration updates required in modern distributed systems. The ztunnel proxy also obtains mTLS certificates for the Service Accounts of all pods that are scheduled on its Kubernetes node using xDS. A single ztunnel proxy may implement L4 data plane functionality on behalf of any pod sharing it's node which requires efficiently obtaining relevant configuration and certificates. This multi-tenant architecture contrasts sharply with the sidecar model where each application pod has its own proxy.
ztunnel 代理使用 xDS API 与 Istio 控制平面（`istiod`）进行通信。
这使得现代分布式系统所需的快速、动态配置更新成为可能。
ztunnel 代理还为使用 xDS 在其 Kubernetes 节点上调度的所有 Pod 的服务帐户获取mTLS 证书。
单个 ztunnel 代理可以代表共享其节点的任何 Pod 实现 L4 数据平面功能，
这需要有效获取相关配置和证书。这种多租户架构与 Sidecar 模型形成鲜明对比，
在 Sidecar 模型中，每个应用程序 Pod 都有自己的代理。

It is also worth noting that in ambient mode, a simplified set of resources are used in the xDS APIs for ztunnel proxy configuration. This results in improved performance (having to transmit and process a much smaller set of information that is sent from istiod to the ztunnel proxies) and improved troubleshooting.
另外值得注意的是，在 Ambient 模式下，xDS API 中使用一组简化的资源来进行 ztunnel 代理配置。
这会提高性能（需要传输和处理从 istiod 发送到 ztunnel 代理的非常小的信息集）并改进排障过程。

### Data plane overview
### 数据平面概述  {#data-plane-overview}

This section briefly summarizes key aspects of the data plane functionality.
本节简要总结了数据平面功能的关键内容。

#### Ztunnel to ztunnel datapath
#### ztunnel 到 ztunnel 数据路径  {#ztunnel-to-ztunnel-datapath}

The first scenario is ztunnel to ztunnel L4 networking. This is depicted in the following figure.
第一个场景是 ztunnel 到 ztunnel L4 网络。如下图所示。

{{< image width="100%"
link="ztunnel-datapath-1.png"
caption="Basic ztunnel L4-only datapath"
>}}
{{< image width="100%"
link="ztunnel-datapath-1.png"
caption="ztunnel 基础：仅 L4 数据路径"
>}}

The figure depicts ambient pod workloads running on two nodes W1 and W2 of a Kubernetes cluster. There is a single instance of the ztunnel proxy on each node. In this scenario, application client pods C1, C2 and C3 need to access a service provided by pod S1 and there is no requirement for advanced L7 features such as L7 traffic routing or L7 traffic management so no Waypoint proxy is needed.
该图描绘了 Kubernetes 集群的两个节点 W1 和 W2 上运行的 Ambient Pod 工作负载。
每个节点上都有一个 ztunnel 代理实例。在此场景中，应用程序客户端
Pod C1、C2 和 C3 需要访问 Pod S1 提供的服务，并且不需要高级 L7 功能
（例如 L7 流量路由或 L7 流量管理），因此不需要 waypoint 代理。

The figure shows that pods C1 and C2 running on node W1 connect with pod S1 running on node W2 and their TCP traffic is tunneled through a single shared HBONE tunnel instance that has been created between the ztunnel proxy pods of each node. Mutual TLS (mTLS) is used for encryption as well as mutual authentication of traffic being tunneled. SPIFFE identities are used to identify the workloads on each side of the connection. The term `HBONE` (for HTTP Based Overlay Network Encapsulation) is used in Istio ambient to refer to a technique for transparently and securely tunneling TCP packets encapsulated within HTTPS packets. Some brief additional notes on HBONE are provided in a following subsection.
该图展示了在节点 W1 上运行的 Pod C1 和 C2 与在节点 W2 上运行的 Pod S1 连接，
它们的 TCP 流量通过在每个节点的 ztunnel 代理 Pod 之间创建的单个共享 HBONE 隧道实例进行隧道传输。
双向 TLS（mTLS）用于加密以及隧道流量的相互身份验证。SPIFFE 身份用于识别连接两端的工作负载。
Istio Ambient 中使用的 `HBONE`（基于 HTTP 的覆盖网络封装：HTTP Based Overlay Network Encapsulation）概念是指一种透明、
安全地隧道传输封装在 HTTPS 数据包中的 TCP 数据包的技术。
以下小节提供了有关 HBONE 的一些简短附加说明。

Note that the figure shows that local traffic - from pod C3 to destination pod S1 on worker node W2 - also traverses the local ztunnel proxy instance so that L4 traffic management functions such as L4 Authorization and L4 Telemetry are enforced identically on traffic, whether or not it crosses a node boundary.
请注意，该图展示本地流量（从 Pod C3 到工作节点 W2 上的目标 Pod S1）也会遍历本地 ztunnel 代理实例，
以便对流量执行相同的 L4 流量管理功能（例如 L4 授权和 L4 遥测），无论它是否跨越节点边界。

#### Ztunnel datapath via waypoint
#### 通过 waypoint 的 ztunnel 数据路径  {#ztunnel-datapath-via-waypoint}

The next figure depicts the data path for a use case which requires advanced L7 traffic routing, management or policy handling. Here ztunnel uses HBONE tunneling to send traffic to a waypoint proxy for L7 processing. After processing, the waypoint sends traffic via a second HBONE tunnel to the ztunnel on the node hosting the selected service destination pod. In general the waypoint proxy may or may not be located on the same nodes as the source or destination pod.
下图描述了需要高级 L7 流量路由、管理或策略处理用例的数据路径。
这里 ztunnel 使用 HBONE 隧道将流量发送到 waypoint 代理进行 L7 处理。
处理后，waypoint 通过第二个 HBONE 隧道将流量发送到托管所选服务目标 Pod 节点上的 ztunnel。
一般来说，waypoint 代理可能位于也可能不位于与源或目标 Pod 相同的节点上。

{{< image width="100%"
link="ztunnel-waypoint-datapath.png"
caption="Ztunnel datapath via an interim waypoint"
>}}
{{< image width="100%"
link="ztunnel-waypoint-datapath.png"
caption="通过临时 waypoint 的 ztunnel 数据路径"
>}}

#### Ztunnel datapath hair-pinning
#### ztunnel 数据路径发夹  {#ztunnel-datapath-hair-pinning}

{{< warning >}}
As noted earlier, some ambient functions may change as the project moves to beta status and beyond. This feature (hair-pinning) is an example of a feature that is currently available in the alpha version of ambient and under review for possible modification as the project evolves.
如前所述，随着项目进入 Beta 及更高版本，一些 Ambient 功能可能会发生变化。
此功能（发夹）是当前在 Ambient 的 Alpha 版本中可用的功能示例，
并且随着项目的发展正在审查可能的修改。
{{< /warning >}}

It was noted earlier that traffic is always sent to a destination pod by first sending it to the ztunnel proxy on the same node as the destination pod. But what if the sender is either completely outside the Istio ambient mesh and hence does not initiate HBONE tunnels to the destination ztunnel first ? What if the sender is malicious and trying to send traffic directly to an ambient pod destination, bypassing the destination ztunnel proxy ?
前面已经指出，流量发送到目标 Pod 时，始终首先将其发送到与目标 Pod 位于同一节点上的 ztunnel 代理。
但是，如果发送方完全位于 Istio Ambient 网格之外，因此没有预先启动到目标 ztunnel 的 HBONE 隧道，该怎么办？
如果发送者是恶意的并尝试绕过目标 ztunnel 代理将流量直接发送到 Ambient Pod 目标怎么办？

There are two scenarios here both of which are depicted in the following figure. In the first scenario, traffic stream B1 is being received by node W2 outside of any HBONE tunnel and addressed directly to ambient pod S1's IP address for some reason (maybe because the traffic source is not an ambient pod). As shown in the figure, the ztunnel traffic redirection logic will intercept such traffic and redirect it via the local ztunnel proxy for destination side proxy processing and possible filtering based on AuthorizationPolicy prior to sending it into pod S1. In the second scenario, traffic stream G1 is being received by the ztunnel proxy of node W2 (possibly over an HBONE tunnel) but the ztunnel proxy checks that the destination service requires waypoint processing and yet the source sending this traffic is not a waypoint or is not associated with this destination service. In this case. again the ztunnel proxy hairpins the traffic towards one of the waypoints associated with the destination service from where it can then be delivered to any pod implementing the destination service (possibly to pod S1 itself as shown in the figure).
这里有两种情况，如下图所示。在第一种情况下，流量流 B1 由任何 HBONE 隧道外部的节点 W2 接收，
并出于某种原因直接寻址到 Ambient Pod S1 的 IP 地址（可能是因为流量源不是 Ambient Pod）。
如图所示，ztunnel 流量重定向逻辑将拦截此类流量，并通过本地 ztunnel 代理将其重定向，
以进行目标端代理处理，并在将其发送到 Pod S1 之前根据 AuthorizationPolicy 进行可能的过滤。
在第二种情况下，流量流 G1 正在由节点 W2 的 ztunnel 代理接收（可能通过 HBONE 隧道），
但 ztunnel 代理检查目标服务是否需要 waypoint 处理，但发送此流量的源不是 waypoint
或者是与此目标服务无关。在这种情况下。ztunnel 代理再次将流量发夹到与目标服务关联的 waypoint 之一，
然后可以将流量从那里传递到实现目标服务的任何 Pod（可能是 Pod S1 本身，如图所示）。

{{< image width="100%"
link="ztunnel-hairpin.png"
caption="Ztunnel traffic hair-pinning"
>}}
{{< image width="100%"
link="ztunnel-hairpin.png"
caption="ztunnel 流量发夹"
>}}

### Note on HBONE {#hbonesection}
### 关于 HBONE 的说明  {#hbonesection}

HBONE (HTTP Based Overlay Network Encapsulation) is an Istio-specific term. It refers to the use of standard HTTP tunneling via the [HTTP CONNECT](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/CONNECT) method to transparently tunnel application packets/ byte streams. In its current implementation within Istio, it transports TCP packets only by tunneling these transparently using the HTTP CONNECT method, uses [HTTP/2](https://httpwg.org/specs/rfc7540.html), with encryption and mutual authentication provided by [mutual TLS](https://www.cloudflare.com/learning/access-management/what-is-mutual-tls/) and the HBONE tunnel itself runs on TCP port 15008. The overall HBONE packet format from IP layer onwards is depicted in the following figure.
HBONE（基于 HTTP 的覆盖网络封装）是 Istio 特定的术语。
它是指通过 [HTTP CONNECT](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/CONNECT)
方法使用标准 HTTP 隧道来透明地隧道应用程序数据包/字节流。
在 Istio 的当前实现中，它仅通过使用 HTTP CONNECT 方法透明地隧道传输 TCP 数据包，
使用 [HTTP/2](https://httpwg.org/specs/rfc7540.html)，
并通过[双向 TLS](https://www.cloudflare.com/learning/access-management/what-is-mutual-tls/)
提供加密和相互身份验证且 HBONE 隧道本身在 TCP 端口 15008 上运行。
来自 IP 层的整体 HBONE 数据包格式 如下图所示。

{{< image width="100%"
link="hbone-packet.png"
caption="HBONE L3 packet format"
>}}
{{< image width="100%"
link="hbone-packet.png"
caption="HBONE L3 数据包格式"
>}}

In future Istio Ambient may also support [HTTP/3 (QUIC)](https://datatracker.ietf.org/doc/html/rfc9114) based transport and will be used to transport all types of L3 and L4 packets including native IPv4, IPv6, UDP by leveraging new standards such as CONNECT-UDP and CONNECT-IP being developed as part of the [IETF MASQUE](https://ietf-wg-masque.github.io/) working group. Such additional use cases of HBONE and HTTP tunneling in Istio's ambient mode are currently for further investigation.
未来 Istio Ambient 还可能支持基于
[HTTP/3 (QUIC)](https://datatracker.ietf.org/doc/html/rfc9114) 的传输，
并将用于传输所有类型的 L3 和 L4 数据包，包括本机 IPv4 、IPv6、UDP，
利用作为 [IETF MASQUE](https://ietf-wg-masque.github.io/)
工作组一部分开发的 CONNECT-UDP 和 CONNECT-IP 等新标准。
Istio 环境模式下的 HBONE 和 HTTP 隧道的此类额外用例目前正在进一步研究。

## Deploying an Application {#deployapplication}
## 部署应用程序  {#deployapplication}

Normally, a user with Istio admin privileges will deploy the Istio mesh infrastructure. Once Istio is successfully deployed in ambient mode, it will be transparently available to applications deployed by all users in namespaces that have been annotated to use Istio ambient as illustrated in the examples below.
通常，具有 Istio 管理员权限的用户将部署 Istio 网格基础设施。
一旦 Istio 在环境模式下成功部署，它将透明地可供命名空间中所有用户部署的应用程序使用，
这些应用程序已被注释为使用 Istio 环境，如下面的示例所示。

### Basic application deployment without Ambient
### 部署不基于 Ambient 的基础应用程序  {#basic-application-deployment-without-ambient}

First, deploy a simple HTTP client server application without making it part of the Istio ambient mesh. Execute the following examples from the top of a local Istio repository or Istio folder created by downloading the istioctl client as described in Istio guides.
首先，部署一个简单的 HTTP 客户端服务器应用程序，而不使其成为 Istio 环境网格的一部分。
从本地 Istio 存储库或通过下载 istioctl 客户端创建的 Istio 文件夹的顶部执行以下示例，
如 Istio 指南中所述。

{{< text bash >}}
$ kubectl create ns ambient-demo
$ kubectl apply -f samples/httpbin/httpbin.yaml -n ambient-demo
$ kubectl apply -f samples/sleep/sleep.yaml -n ambient-demo
$ kubectl apply -f samples/sleep/notsleep.yaml -n ambient-demo
$ kubectl scale deployment sleep --replicas=2 -n ambient-demo
{{< /text >}}

These manifests deploy multiple replicas of the `sleep` and `notsleep` pods which will be used as clients for the httpbin service pod (for simplicity, the command-line outputs have been deleted in the code samples above).
这些清单部署了“sleep”和“notsleep” Pod 的多个副本，这些副本将用作 httpbin
服务 Pod 的客户端（为简单起见，上面的代码示例中的命令行输出已被删除）。

{{< text bash >}}
$ kubectl wait -n ambient-demo --for=condition=ready pod --selector=app=httpbin --timeout=90s
pod/httpbin-648cd984f8-7vg8w condition met
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n ambient-demo
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-648cd984f8-7vg8w   1/1     Running   0          31m
notsleep-bb6696574-2tbzn   1/1     Running   0          31m
sleep-69cfb4968f-mhccl     1/1     Running   0          31m
sleep-69cfb4968f-rhhhp     1/1     Running   0          31m
{{< /text >}}

{{< text bash >}}
$ kubectl get svc httpbin -n ambient-demo
NAME      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
httpbin   ClusterIP   10.110.145.219   <none>        8000/TCP   28m
{{< /text >}}

Note that each application pod has just 1 container running in it (the "1/1" indicator) and that `httpbin` is an http service listening on `ClusterIP` service port 8000. You should now be able to `curl` this service from either client pod and confirm it returns the `httpbin` web page as shown below. At this point there is no `TLS` of any form being used.
请注意，每个应用程序 Pod 中仅运行 1 个容器（“1/1”指示符），
并且“httpbin”是侦听“ClusterIP”服务端口 8000 的 http 服务。
您现在应该能够“curl”此服务 从任一客户端 pod 并确认它返回“httpbin”网页，
如下所示。 此时，还没有使用任何形式的“TLS”。

{{< text bash >}}
$ kubectl exec deploy/sleep -n ambient-demo  -- curl httpbin:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

### Enabling ambient for an application
### 为应用程序启用 Ambient  {#enabling-ambient-for-an-application}

You can now enable ambient for the application deployed in the prior subsection by simply adding the label `istio.io/dataplane-mode=ambient` to the application's namespace as shown below. Note that this example focuses on a fresh namespace with new, sidecar-less workloads captured via ambient mode only. Later sections will describe how conflicts are resolved in hybrid scenarios that mix sidecar mode and ambient mode within the same mesh.
现在，您只需将标签“istio.io/dataplane-mode=ambient”
添加到应用程序的命名空间即可为上一小节中部署的应用程序启用环境，如下所示。
请注意，此示例重点关注一个新的命名空间，其中包含仅通过环境模式捕获的新的、
无 sidecar 的工作负载。 后面的部分将描述如何在同一网格内混合 sidecar
模式和环境模式的混合场景中解决冲突。

{{< text bash >}}
$ kubectl label namespace ambient-demo istio.io/dataplane-mode=ambient
$ kubectl  get pods -n ambient-demo
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-648cd984f8-7vg8w   1/1     Running   0          78m
notsleep-bb6696574-2tbzn   1/1     Running   0          77m
sleep-69cfb4968f-mhccl     1/1     Running   0          78m
sleep-69cfb4968f-rhhhp     1/1     Running   0          78m
{{< /text >}}

Note that after ambient is enabled for the namespace, every application pod still only has 1 container, and the uptime of these pods indicates these were not restarted in order to enable ambient mode (unlike `sidecar` mode which does restart application pods when the sidecar proxies are injected). This results in better user experience and operational performance since ambient mode can seamlessly be enabled (or disabled) completely transparently as far as the application pods are concerned.
请注意，为命名空间启用环境后，每个应用程序 pod 仍然只有 1 个容器，
并且这些 pod 的正常运行时间表明这些 pod 没有为了启用环境模式而重新启动
（与 sidecar 模式不同，当 sidecar 启动时，它会重新启动应用程序 pod） 代理被注入）。
这会带来更好的用户体验和操作性能，因为就应用程序 Pod 而言，
可以完全透明地无缝启用（或禁用）环境模式。

Initiate a `curl` request again from one of the client pods to the service to verify that traffic continues to flow while ambient mode.
再次从客户端 Pod 之一向服务发起“curl”请求，以验证流量在环境模式下是否继续流动。

{{< text bash >}}
$ kubectl exec deploy/sleep -n ambient-demo  -- curl httpbin:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

This indicates the traffic path is working. The next section looks at how to monitor the configuration and data plane of the ztunnel proxy to confirm that traffic is correctly using the ztunnel proxy.
这表明流量路径正在工作。 下一节将介绍如何监控 ztunnel 代理的配置和数据平面，
以确认流量正确使用 ztunnel 代理。

## Monitoring the ztunnel proxy & L4 networking {#monitoringzt}
## 监控 ztunnel 代理和 L4 网络  {#monitoringzt}

This section describes some options for monitoring the ztunnel proxy configuration and data path. This information can also help with some high level troubleshooting and in identifying information that would be useful to collect and provide in a bug report if there are any problems. Additional advanced monitoring of ztunnel internals and advanced troubleshooting is out of scope for this guide.
本节介绍一些用于监视 ztunnel 代理配置和数据路径的选项。
此信息还可以帮助进行一些高级故障排除，以及识别在出现任何问题时可在错误报告中收集和提供的有用信息。
ztunnel 内部的其他高级监控和高级故障排除超出了本指南的范围。

### Viewing ztunnel proxy state
### 查看 ztunnel 代理状态

As indicated previously, the ztunnel proxy on each node gets configuration and discovery information from the istiod component via xDS APIs. Use the `istioctl proxy-config` command shown below to view discovered workloads as seen by a ztunnel proxy as well as secrets holding the TLS certificates that the ztunnel proxy has received from the istiod control plane to use in mTLS signaling on behalf of the local workloads.
如前所述，每个节点上的 ztunnel 代理通过 xDS API 从 istiod 组件获取配置和发现信息。
使用如下所示的“istioctl proxy-config”命令查看 ztunnel 代理发现的工作负载，
以及保存 ztunnel 代理从 istiod 控制平面接收到的 TLS 证书的机密，
以代表本地在 mTLS 信令中使用 工作负载。

In the first example, you see all the workloads and control plane components that the specific ztunnel pod is currently tracking including information about the IP address and protocol to use when connecting to that component and whether there is a Waypoint proxy associated with that workload. This example can repeated with any of the other ztunnel pods in the system to display their current configuration.
在第一个示例中，您会看到特定 ztunnel Pod 当前正在跟踪的所有工作负载和控制平面组件，
包括有关连接到该组件时要使用的 IP 地址和协议的信息，
以及是否存在与该工作负载关联的 Waypoint 代理。
可以对系统中的任何其他 ztunnel Pod 重复此示例，以显示其当前配置。

{{< text bash >}}
$ export ZTUNNEL=$(kubectl get pods -n istio-system -o wide | grep ztunnel -m 1 | sed 's/ .*//')
$ echo "$ZTUNNEL"
{{< /text >}}

{{< text bash >}}
$ istioctl proxy-config workloads "$ZTUNNEL".istio-system
NAME                                   NAMESPACE          IP         NODE               WAYPOINT PROTOCOL
coredns-6d4b75cb6d-ptbhb               kube-system        10.240.0.2 amb1-control-plane None     TCP
coredns-6d4b75cb6d-tv5nz               kube-system        10.240.0.3 amb1-control-plane None     TCP
httpbin-648cd984f8-2q9bn               ambient-demo       10.240.1.5 amb1-worker        None     HBONE
httpbin-648cd984f8-7dglb               ambient-demo       10.240.2.3 amb1-worker2       None     HBONE
istiod-5c7f79574c-pqzgc                istio-system       10.240.1.2 amb1-worker        None     TCP
local-path-provisioner-9cd9bd544-x7lq2 local-path-storage 10.240.0.4 amb1-control-plane None     TCP
notsleep-bb6696574-r4xjl               ambient-demo       10.240.2.5 amb1-worker2       None     HBONE
sleep-69cfb4968f-mwglt                 ambient-demo       10.240.1.4 amb1-worker        None     HBONE
sleep-69cfb4968f-qjmfs                 ambient-demo       10.240.2.4 amb1-worker2       None     HBONE
ztunnel-5jfj2                          istio-system       10.240.0.5 amb1-control-plane None     TCP
ztunnel-gkldc                          istio-system       10.240.1.3 amb1-worker        None     TCP
ztunnel-xxbgj                          istio-system       10.240.2.2 amb1-worker2       None     TCP
{{< /text >}}

In the second example, you see the list of TLS certificates that this ztunnel proxy instance has received from istiod to use in TLS signaling.
在第二个示例中，您会看到此 ztunnel 代理实例从 istiod
接收到的用于 TLS 信令的 TLS 证书列表。

{{< text bash >}}
$ istioctl proxy-config secrets "$ZTUNNEL".istio-system
NAME                                                  TYPE           STATUS        VALID CERT     SERIAL NUMBER                        NOT AFTER                NOT BEFORE
spiffe://cluster.local/ns/ambient-demo/sa/httpbin     CA             Available     true           edf7f040f4b4d0b75a1c9a97a9b13545     2023-09-20T19:02:00Z     2023-09-19T19:00:00Z
spiffe://cluster.local/ns/ambient-demo/sa/httpbin     Cert Chain     Available     true           ec30e0e1b7105e3dce4425b5255287c6     2033-09-16T18:26:19Z     2023-09-19T18:26:19Z
spiffe://cluster.local/ns/ambient-demo/sa/sleep       CA             Available     true           3b9dbea3b0b63e56786a5ea170995f48     2023-09-20T19:00:44Z     2023-09-19T18:58:44Z
spiffe://cluster.local/ns/ambient-demo/sa/sleep       Cert Chain     Available     true           ec30e0e1b7105e3dce4425b5255287c6     2033-09-16T18:26:19Z     2023-09-19T18:26:19Z
spiffe://cluster.local/ns/istio-system/sa/istiod      CA             Available     true           885ee63c08ef9f1afd258973a45c8255     2023-09-20T18:26:34Z     2023-09-19T18:24:34Z
spiffe://cluster.local/ns/istio-system/sa/istiod      Cert Chain     Available     true           ec30e0e1b7105e3dce4425b5255287c6     2033-09-16T18:26:19Z     2023-09-19T18:26:19Z
spiffe://cluster.local/ns/istio-system/sa/ztunnel     CA             Available     true           221b4cdc4487b60d08e94dc30a0451c6     2023-09-20T18:26:35Z     2023-09-19T18:24:35Z
spiffe://cluster.local/ns/istio-system/sa/ztunnel     Cert Chain     Available     true           ec30e0e1b7105e3dce4425b5255287c6     2033-09-16T18:26:19Z     2023-09-19T18:26:19Z
{{< /text >}}

Using these CLI commands, a user can check that ztunnel proxies are getting configured with all the expected workloads and TLS certificates and missing information can be used for troubleshooting to explain any potential observed networking errors. A user may also use the `all` option to view all parts of the proxy-config with a single CLI command and the JSON output formatter as shown in the example below to display the complete set of available state information.
使用这些 CLI 命令，用户可以检查 ztunnel 代理是否已配置所有预期的工作负载和 TLS 证书，
并且缺失的信息可用于故障排除，以解释任何潜在的观察到的网络错误。
用户还可以使用“all”选项通过单个 CLI 命令和 JSON
输出格式化程序来查看代理配置的所有部分，如下例所示，以显示完整的可用状态信息集。

{{< text bash >}}
$ istioctl proxy-config all "$ZTUNNEL".istio-system -o json | jq
{{< /text >}}

Note that when used with a ztunnel proxy instance, not all options of the `istioctl proxy-config` CLI are supported since some apply only to sidecar proxies.
请注意，与 ztunnel 代理实例一起使用时，并非支持“istioctl proxy-config”
CLI 的所有选项，因为某些选项仅适用于 sidecar 代理。

An advanced user may also view the raw configuration dump of a ztunnel proxy via a `curl` to the endpoint inside a ztunnel proxy pod as shown in the following example.
高级用户还可以通过“curl”到 ztunnel 代理 Pod 内的端点查看
ztunnel 代理的原始配置转储，如以下示例所示。

{{< text bash >}}
$ kubectl exec ds/ztunnel -n istio-system  -- curl http://localhost:15000/config_dump | jq .
{{< /text >}}

### Viewing Istiod state for ztunnel xDS resources
### 查看 ztunnel xDS 资源的 Istiod 状态

Sometimes an advanced user may want to view the state of ztunnel proxy config resources as maintained in the istiod control plane, in the format of the xDS API resources defined specially for ztunnel proxies. This can be done by exec-ing into the istiod pod and obtaining this information from port 15014 for a given ztunnel proxy as shown in the example below. This output can then also be saved and viewed with a JSON pretty print formatter utility for easier browsing (not shown in the example).
有时，高级用户可能希望以专门为 ztunnel 代理定义的 xDS API 资源的格式查看 istiod
控制平面中维护的 ztunnel 代理配置资源的状态。这可以通过执行 istiod pod
并从给定 ztunnel 代理的端口 15014 获取此信息来完成，如下例所示。
然后，还可以使用 JSON 漂亮的打印格式化程序实用程序保存和查看此输出，
以便于浏览（示例中未显示）。

{{< text bash >}}
$ kubectl exec -n istio-system deploy/istiod -- curl localhost:15014/debug/config_dump?proxyID="$ZTUNNEL".istio-system | jq
{{< /text >}}

### Verifying ztunnel traffic logs
### 验证 ztunnel 流量日志

Send some traffic from a client `sleep` pod to the `httpbin` service.
将一些流量从客户端 `sleep` pod 发送到 `httpbin` 服务。

{{< text bash >}}
$ kubectl -n ambient-demo exec deploy/sleep -- sh -c 'for i in $(seq 1 10); do curl -s -I http://httpbin:8000/; done'
HTTP/1.1 200 OK
Server: gunicorn/19.9.0
--snip--
{{< /text >}}

The response displayed confirms the client pod receives responses from the service. Now check logs of the ztunnel pods to confirm the traffic was sent over the HBONE tunnel.
显示的响应确认客户端 Pod 收到来自服务的响应。
现在检查 ztunnel pod 的日志以确认流量是通过 HBONE 隧道发送的。

{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | grep -E "inbound|outbound"
2023-08-14T09:15:46.542651Z  INFO outbound{id=7d344076d398339f1e51a74803d6c854}: ztunnel::proxy::outbound: proxying to 10.240.2.10:80 using node local fast path
2023-08-14T09:15:46.542882Z  INFO outbound{id=7d344076d398339f1e51a74803d6c854}: ztunnel::proxy::outbound: complete dur=269.272µs
--snip--
{{< /text >}}

These log messages confirm the traffic indeed used the ztunnel proxy in the datapath. Additional fine grained monitoring can be done by checking logs on the specific ztunnel proxy instances that are on the same nodes as the source and destination pods of traffic. If these logs are not seen, then a possibility is that traffic redirection may not be working correctly. Detailed description of monitoring and troubleshooting of the traffic redirection logic is out of scope for this guide. Note that as mentioned previously, with ambient traffic always traverses the ztunnel pod even when the source and destination of the traffic are on the same compute node.
这些日志消息确认流量确实使用了数据路径中的 ztunnel 代理。
可以通过检查与流量源和目标 pod 位于同一节点上的特定 ztunnel
代理实例上的日志来完成额外的细粒度监控。 如果没有看到这些日志，
则可能是流量重定向无法正常工作。流量重定向逻辑的监控和故障排除的详细描述超出了本指南的范围。
请注意，如前所述，即使流量的源和目的地位于同一计算节点上，环境流量也始终会遍历 ztunnel pod。

### Monitoring and Telemetry via Prometheus, Grafana, Kiali
### 通过 Prometheus、Grafana、Kiali 进行监控和遥测

In addition to checking ztunnel logs and other monitoring options noted above, one can also use normal Istio monitoring and telemetry functions to monitor application traffic within an Istio Ambient mesh. The use of Istio in ambient mode does not change this behavior. Since this functionality is largely unchanged in Istio ambient mode from Istio sidecar mode , these details are not repeated in this guide. Please refer to [Prometheus](/docs/ops/integrations/prometheus/#installation) and [Kiali](/docs/ops/integrations/kiali/#installation) for information on installation of Prometheus and Kiali services and dashboards as well as the standard Istio metrics and telemetry documentation (such as [here](/docs/reference/config/metrics/) and [here](/docs/tasks/observability/metrics/querying-metrics/)) for additional details.
除了检查 ztunnel 日志和上述其他监控选项之外，还可以使用普通的 Istio
监控和遥测功能来监控 Istio Ambient 网格内的应用程序流量。
在环境模式下使用 Istio 不会改变此行为。 由于此功能在 Istio 环境模式下与
Istio sidecar 模式基本没有变化，因此本指南中不再重复这些细节。
请参阅 [Prometheus](/docs/ops/integrations/prometheus/#installation)
和 [Kiali](/docs/ops/integrations/kiali/#installation)
了解 Prometheus 和 Kiali 服务和仪表板的安装信息以及 标准 Istio 指标和遥测文档
（例如[此处](/docs/reference/config/metrics/) 
和[此处](/docs/tasks/observability/metrics/querying-metrics/)）了解更多详细信息。

One point to note is that in case of a service that is only using ztunnel and L4 networking, the Istio metrics reported will currently only be the L4/ TCP metrics (namely `istio_tcp_sent_bytes_total`, `istio_tcp_received_bytes_total`, `istio_tcp_connections_opened_total`, `istio_tcp_connections_closed_total`). The full set of Istio and Envoy metrics will be reported when a Waypoint proxy is involved.
需要注意的一点是，如果服务仅使用 ztunnel 和 L4 网络，
则报告的 Istio 指标目前仅是 L4/ TCP 指标（即 `istio_tcp_sent_bytes_total`、
`istio_tcp_received_bytes_total`、`istio_tcp_connections_opened_total`、
`istio_tcp_connections_filled_total` ）。
当涉及 Waypoint 代理时，将报告全套 Istio 和 Envoy 指标。

### Verifying ztunnel load balancing
### 验证 ztunnel 负载平衡

The ztunnel proxy automatically performs client-side load balancing if the destination is a service with multiple endpoints. No additional configuration is needed. The ztunnel load balancing algorithm is an internally fixed L4 Round Robin algorithm that distributes traffic based on L4 connection state and is not user configurable.
如果目标是具有多个端点的服务，ztunnel 代理会自动执行客户端负载平衡。
无需额外配置。 ztunnel负载均衡算法是内部固定的L4循环算法，
根据L4连接状态分配流量，用户不可配置。

{{< tip >}}
If the destination is a service with multiple instances or pods and there is no Waypoint associated with the destination service, then the source ztunnel proxy performs L4 load balancing directly across these instances or service backends and then sends traffic via the remote ztunnel proxies associated with those backends. If the destination service does have a Waypoint deployment (with one or more backend instances of the Waypoint proxy) associated with it, then the source ztunnel proxy performs load balancing by distributing traffic across these Waypoint proxies and sends traffic via the remote ztunnel proxies associated with the Waypoint proxy instances.
如果目标是具有多个实例或 Pod 的服务，并且没有与目标服务关联的 Waypoint，
则源 ztunnel 代理直接跨这些实例或服务后端执行 L4 负载平衡，
然后通过与这些实例或服务后端关联的远程 ztunnel 代理发送流量 后端。
如果目标服务确实具有与其关联的 Waypoint 部署（具有一个或多个 Waypoint
代理的后端实例），则源 ztunnel 代理通过在这些 Waypoint 代理之间分配流量来执行负载平衡，
并通过与关联的远程 ztunnel 代理发送流量 Waypoint 代理实例。
{{< /tip >}}

Now repeat the previous example with multiple replicas of the service pod and verify that client traffic is load balanced across the service replicas. Wait for all pods in the ambient-demo namespace to go into Running state before continuing to the next step.
现在，使用服务 Pod 的多个副本重复前面的示例，
并验证客户端流量是否在服务副本之间实现负载平衡。
等待ambient-demo命名空间中的所有pod进入Running状态，然后再继续下一步。

{{< text bash >}}
$ kubectl -n ambient-demo scale deployment httpbin --replicas=2 ; kubectl wait --for condition=available  deployment/httpbin -n ambient-demo
deployment.apps/httpbin scaled
deployment.apps/httpbin condition met
{{< /text >}}

{{< text bash >}}
$ kubectl -n ambient-demo exec deploy/sleep -- sh -c 'for i in $(seq 1 10); do curl -s -I http://httpbin:8000/; done'
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | grep -E "inbound|outbound"
--snip--

2023-08-14T09:33:24.969996Z  INFO inbound{id=ec177a563e4899869359422b5cdd1df4 peer_ip=10.240.2.16 peer_id=spiffe://cluster.local/ns/ambient-demo/sa/sleep}: ztunnel::proxy::inbound: got CONNECT request to 10.240.1.11:80
2023-08-14T09:33:25.028601Z  INFO inbound{id=1ebc3c7384ee68942bbb7c7ed866b3d9 peer_ip=10.240.2.16 peer_id=spiffe://cluster.local/ns/ambient-demo/sa/sleep}: ztunnel::proxy::inbound: got CONNECT request to 10.240.1.11:80

--snip--

2023-08-14T09:33:25.226403Z  INFO outbound{id=9d99723a61c9496532d34acec5c77126}: ztunnel::proxy::outbound: proxy to 10.240.1.11:80 using HBONE via 10.240.1.11:15008 type Direct
2023-08-14T09:33:25.273268Z  INFO outbound{id=9d99723a61c9496532d34acec5c77126}: ztunnel::proxy::outbound: complete dur=46.9099ms
2023-08-14T09:33:25.276519Z  INFO outbound{id=cc87b4de5ec2ccced642e22422ca6207}: ztunnel::proxy::outbound: proxying to 10.240.2.10:80 using node local fast path
2023-08-14T09:33:25.276716Z  INFO outbound{id=cc87b4de5ec2ccced642e22422ca6207}: ztunnel::proxy::outbound: complete dur=231.892µs

--snip--
{{< /text >}}

Here note the logs from the ztunnel proxies first indicating the http CONNECT request to the new destination pod (10.240.1.11) which indicates the setup of the HBONE tunnel to ztunnel on the node hosting the additional destination service pod. This is then followed by logs indicating the client traffic being sent to both 10.240.1.11 and 10.240.2.10 which are the two destination pods providing the service. Also note that the data path is performing client-side load balancing in this case and not depending on Kubernetes service load balancing. In your setup these numbers will be different and will match the pod addresses of the httpbin pods in your cluster.
请注意来自 ztunnel 代理的日志，首先指示对新目标 Pod (10.240.1.11) 的
http CONNECT 请求，该请求指示在托管其他目标服务 Pod 的节点上设置到
ztunnel 的 HBONE 隧道。 接下来的日志指示客户端流量发送到 10.240.1.11
和 10.240.2.10，这是提供服务的两个目标 Pod。 另请注意，在这种情况下，
数据路径正在执行客户端负载平衡，而不是依赖于 Kubernetes 服务负载平衡。
在您的设置中，这些数字将有所不同，并将与集群中 httpbin pod 的 pod 地址匹配。

This is a round robin load balancing algorithm and is separate from and independent of any load balancing algorithm that may be configured within a `VirtualService`'s `TrafficPolicy` field, since as discussed previously, all aspects of `VirtualService` API objects are instantiated on the Waypoint proxies and not the ztunnel proxies.
这是一种循环负载平衡算法，并且独立于可以在 `VirtualService` 的 `TrafficPolicy`
字段中配置的任何负载平衡算法，因为如前所述，`VirtualService` API
对象的所有方面都被实例化 在 Waypoint 代理上而不是 ztunnel 代理上。

### Pod selection logic for ambient and sidecar modes
### 环境模式和边车模式的 Pod 选择逻辑

Istio with sidecar proxies can co-exist with ambient based node level proxies within the same compute cluster. It is important to ensure that the same pod or namespace does not get configured to use both a sidecar proxy and an ambient node-level proxy. However if this does occur, currently sidecar injection takes precedence for such a pod or namespace.
具有 sidecar 代理的 Istio 可以与同一计算集群中基于环境的节点级代理共存。
确保相同的 pod 或命名空间不会配置为同时使用 sidecar 代理和环境节点级代理非常重要。
但是，如果确实发生这种情况，当前此类 pod 或命名空间将优先进行 sidecar 注入。

Note that two pods within the same namespace could in theory be set to use different modes by labeling individual pods separately from the namespace label, however this is not recommended. For most common use cases it is recommended that a single mode be used for all pods within a single namespace.
请注意，理论上，可以通过将各个 pod 与命名空间标签分开标记来将同一命名空间中的两个
pod 设置为使用不同的模式，但不建议这样做。 对于大多数常见用例，
建议对单个命名空间内的所有 Pod 使用单一模式。

The exact logic to determine whether a pod is setup to use ambient mode is as follows.
确定 pod 是否设置为使用环境模式的确切逻辑如下。

1. The `istio-cni` plugin configuration exclude list configured in `cni.values.excludeNamespaces` is used to skip namespaces in the exclude list.
1. `ambient` mode is used for a pod if
- The namespace has label `istio.io/dataplane-mode=ambient`
- The annotation `sidecar.istio.io/status` is not present on the pod
- `ambient.istio.io/redirection` is not `disabled`
1. `cni.values.excludeNamespaces` 中配置的 `istio-cni`
   插件配置排除列表用于跳过排除列表中的命名空间。
1. pod 使用 `ambient` 模式，如果
- 命名空间具有标签 `istio.io/dataplane-mode=ambient`
- Pod 上不存在注释 `sidecar.istio.io/status`
- `ambient.istio.io/redirection` 不是 `disabled`

The simplest option to avoid a configuration conflict is for a user to ensure that for each namespace, it either has the label for sidecar injection (`istio-injection=enabled`) or for ambient data plane mode (`istio.io/dataplane-mode=ambient`) but never both.
避免配置冲突的最简单选项是用户确保对于每个命名空间，
它要么具有 sidecar 注入标签（`istio-injection=enabled`），
要么具有环境数据平面模式标签（`istio.io/dataplane- mode=ambient`），
但绝不能两者兼而有之。

## L4 Authorization Policy {#l4auth}
## L4 授权策略  {#l4auth}

As mentioned previously, the ztunnel proxy performs Authorization policy enforcement when it requires only L4 traffic processing in order to enforce the policy in the data plane and there are no Waypoints involved. The actual enforcement point is at the receiving (or server side) ztunnel proxy in the path of a connection.
如前所述，ztunnel 代理在仅需要 L4
流量处理以便在数据平面中实施策略并且不涉及路点时执行授权策略实施。
实际的执行点位于连接路径中的接收（或服务器端）ztunnel 代理。

Apply a basic L4 Authorization policy for the already deployed `httpbin` application as shown in the example below.
为已部署的“httpbin”应用程序应用基本的 L4 授权策略，如下例所示。

{{< text bash >}}
$ kubectl apply -n ambient-demo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: allow-sleep-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/sleep
EOF
{{< /text >}}

The behavior of the `AuthorizationPolicy` API has the same functional behavior in Istio ambient mode as in sidecar mode. When there is no `AuthorizationPolicy` provisioned, then the default action is `ALLOW`. Once the policy above is provisioned, pods matching the selector in the policy (i.e. app:httpbin) only allow traffic explicitly whitelisted which in this case is sources with principal (i.e. identity) of `cluster.local/ns/ambient-demo/sa/sleep`. Now as shown below, if you try the curl operation to the `httpbin` service from the `sleep` pods, it still works but the same operation is blocked when initiated from the `notsleep` pods.
`AuthorizationPolicy` API 的行为在 Istio 环境模式下与 Sidecar
模式下具有相同的功能行为。当没有配置 `AuthorizationPolicy` 时，默认操作是 `ALLOW`。
配置上述策略后，与策略中的选择器（即 app:httpbin）匹配的 Pod 仅允许明确列入白名单的流量，
在本例中是主体（即身份）为 `cluster.local/ns/ambient-demo/sa/sleep` 的源 /睡觉`。
现在如下所示，如果您尝试从 `sleep` Pod 对 `httpbin` 服务执行curl 操作，它仍然有效，
但从 `notsleep` Pod 启动时，相同的操作会被阻止。

Note that this policy performs an explicit `ALLOW` action on traffic from sources with principal (i.e. identity) of `cluster.local/ns/ambient-demo/sa/sleep` and hence traffic from all other sources will be denied.
请注意，此策略对来自主体（即身份）为 `cluster.local/ns/ambient-demo/sa/sleep`
的源的流量执行显式 `ALLOW` 操作，因此来自所有其他源的流量将被拒绝。

{{< text bash >}}
$ kubectl exec deploy/sleep -n ambient-demo -- curl httpbin:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

{{< text bash >}}
$ kubectl exec deploy/notsleep -n ambient-demo -- curl httpbin:8000 -s | grep title -m 1
command terminated with exit code 56
{{< /text >}}

Note that there are no waypoint proxies deployed and yet this `AuthorizationPolicy` is getting enforced and this is because this policy only requires L4 traffic processing which can be performed by ztunnel proxies. These policy actions can be further confirmed by checking ztunnel logs and looking for logs that indicate RBAC actions as shown in the following example.
请注意，没有部署路点代理，但此 `AuthorizationPolicy` 正在强制执行，
这是因为此策略仅需要可由 ztunnel 代理执行的 L4 流量处理。
可以通过检查 ztunnel 日志并查找指示 RBAC 操作的日志来进一步确认这些策略操作，
如以下示例所示。

{{< text bash >}}
$ kubectl logs ds/ztunnel -n istio-system  | grep -E RBAC
-- snip --
2023-10-10T23:14:00.534962Z  INFO inbound{id=cc493da5e89877489a786fd3886bd2cf peer_ip=10.240.2.2 peer_id=spiffe://cluster.local/ns/ambient-demo/sa/notsleep}: ztunnel::proxy::inbound: RBAC rejected conn=10.240.2.2(spiffe://cluster.local/ns/ambient-demo/sa/notsleep)->10.240.1.2:80
2023-10-10T23:15:33.339867Z  INFO inbound{id=4c4de8de802befa5da58a165a25ff88a peer_ip=10.240.2.2 peer_id=spiffe://cluster.local/ns/ambient-demo/sa/notsleep}: ztunnel::proxy::inbound: RBAC rejected conn=10.240.2.2(spiffe://cluster.local/ns/ambient-demo/sa/notsleep)->10.240.1.2:80
{{< /text >}}

{{< warning >}}
If an `AuthorizationPolicy` has been configured that requires any traffic processing beyond L4, and if no waypoint proxies are configured for the destination of the traffic, then ztunnel proxy will simply drop all traffic as a defensive move. Hence check to ensure that either all rules involve L4 processing only or else if non-L4 rules are unavoidable, then waypoint proxies are also configured to handle policy enforcement.
如果配置的 `AuthorizationPolicy` 需要 L4 之外的任何流量处理，
并且没有为流量的目的地配置路点代理，则 ztunnel 代理将简单地丢弃所有流量作为防御措施。
因此，请检查以确保所有规则仅涉及 L4 处理，否则如果非 L4 规则不可避免，
则还配置路点代理来处理策略实施。
{{< /warning >}}

As an example, modify the `AuthorizationPolicy` to include a check for the HTTP GET method as shown below. Now notice that both `sleep` and `notsleep` pods are blocked from sending traffic to the destination `httpbin` service.
例如，修改 `AuthorizationPolicy` 以包含对 HTTP GET 方法的检查，
如下所示。现在请注意，`sleep` 和 `notsleep` Pod 都被阻止向目标 `httpbin` 服务发送流量。

{{< text bash >}}
$ kubectl apply -n ambient-demo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: allow-sleep-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/sleep
   to:
   - operation:
       methods: ["GET"]
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl exec deploy/sleep -n ambient-demo -- curl httpbin:8000 -s | grep title -m 1
command terminated with exit code 56
{{< /text >}}

{{< text bash >}}
$ kubectl exec deploy/notsleep -n ambient-demo -- curl httpbin:8000 -s | grep title -m 1
command terminated with exit code 56
{{< /text >}}

You can also confirm by viewing logs of specific ztunnel proxy pods (not shown in the example here) that it is always the ztunnel proxy on the node hosting the destination pod that actually enforces the policy.
您还可以通过查看特定 ztunnel 代理 Pod 的日志（此处示例中未显示）来确认，
实际执行策略的始终是托管目标 Pod 的节点上的 ztunnel 代理。

Go ahead and delete this `AuthorizationPolicy` before continuing with the rest of the examples in the guide.
在继续本指南中的其余示例之前，请先删除此 `AuthorizationPolicy`。

{{< text bash >}}
$ kubectl delete AuthorizationPolicy allow-sleep-to-httpbin  -n ambient-demo
{{< /text >}}

## Ambient Interoperability with non-ambient endpoints {#interop}
## Ambient 与非 Ambient 端点的互操作性  {#interop}

In the use cases so far, the traffic source and destination pods are both ambient pods. This section covers some mixed use cases where ambient endpoints need to communicate with non-ambient endpoints. As with prior examples in this guide, this section covers use cases that do not require waypoint proxies.
在到目前为止的用例中，流量源和目标 Pod 都是 Ambient Pod。
本节介绍一些混合用例，其中 Ambient 端点需要与非 Ambient 端点进行通信。
与本指南前面的示例一样，本节介绍的用例不需要 waypoint 代理。

1. [East-West non-mesh pod to ambient mesh pod (and use of `PeerAuthentication` resource)](#ewnonmesh)
1. [East-West Istio sidecar proxy pod to ambient mesh pod](#ewside2ambient)
1. [North-South Ingress Gateway to ambient backend pods](#nsingress2ambient)
1. [东西向非网状 Pod 到 Ambient 网格 Pod（以及使用 `PeerAuthentication` 资源）](#ewnonmesh)
1. [东西向 Istio Sidecar 代理 Pod 到 Ambient 网格 Pod](#ewside2ambient)
1. [Ambient 后端 Pod 的南北入口网关](#nsingress2ambient)

### East-West non-mesh pod to ambient mesh pod (and use of PeerAuthentication resource) {#ewnonmesh}
### 东西向非网格 Pod 到 Ambient 网格 Pod（以及 PeerAuthentication 资源的使用）  {#ewnonmesh}

In the example below, the same `httpbin` service which has already been setup in the prior examples is accessed via client `sleep` pods that are running in a separate namespace that is not part of the Istio mesh. This example shows that East-west traffic between ambient mesh pods and non mesh pods is seamlessly supported. Note that as described previously, this use case leverages the traffic hair-pinning capability of ambient. Since the non-mesh pods initiate traffic directly to the backend pods without going through HBONE or ztunnel, at the destination node, traffic is redirected via the ztunnel proxy at the destination node to ensure that ambient authorization policy is applied (this can be verified by viewing logs of the appropriate ztunnel proxy pod on the destination node; the logs are not shown in the example snippet below for simplicity).
在下面的示例中，通过在不属于 Istio 网格的单独命名空间中运行的客户端
`sleep` Pod 访问前面示例中已设置的相同“httpbin”服务。
此示例显示 Ambient 网格 Pod 和非网格 Pod 之间的东西向流量得到无缝支持。
请注意，如前所述，此用例利用了 Ambient 的流量发夹功能。
由于非网格 Pod 直接向后端 Pod 发起流量，而不经过 HBONE 或 ztunnel，
因此在目标节点，流量将通过目标节点的 ztunnel 代理进行重定向，
以确保应用 Ambient 授权策略（这可以通过以下方式验证）查看目标节点上相应
ztunnel 代理 Pod 的日志；为简单起见，下面的示例代码片段中未显示日志）。

{{< text bash >}}
$ kubectl create namespace client-a
$ kubectl apply -f samples/sleep/sleep.yaml -n client-a
$ kubectl wait --for condition=available  deployment/sleep -n client-a
{{< /text >}}

Wait for the pods to get to Running state in the client-a namespace before continuing.
等待 Pod 在 client-a 命名空间中进入 Running 状态，然后再继续。

{{< text bash >}}
$ kubectl exec deploy/sleep -n client-a  -- curl httpbin.ambient-demo.svc.cluster.local:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

As shown in the example below, now add a `PeerAuthentication` resource with mTLS mode set to `STRICT`, in the ambient namespace and confirm that the same client's traffic is now rejected with an error indicating the request was rejected. This is because the client is using simple HTTP to connect to the server instead of an HBONE tunnel with mTLS. This is a possible method that can be used to prevent non-Istio sources from sending traffic to Istio ambient pods.
如下面的示例所示，现在在 Ambient 命名空间中添加 mTLS 模式设置为
`STRICT` 的 `PeerAuthentication` 资源，并确认同一客户端的流量现在被拒绝，
并出现一条指示请求被拒绝的错误。这是因为客户端使用简单的 HTTP 连接到服务器，
而不是使用 mTLS 的 HBONE 隧道。这是一种可能的方法，
可用于防止非 Istio 源向 Istio Ambient Pod 发送流量。

{{< text bash >}}
$ kubectl apply -n ambient-demo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: peerauth
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl exec deploy/sleep -n client-a  -- curl httpbin.ambient-demo.svc.cluster.local:8000 -s | grep title -m 1
command terminated with exit code 56
{{< /text >}}

Change the mTLS mode to `PERMISSIVE` and confirm that the ambient pods can once again accept non-mTLS connections including from non-mesh pods in this case.
将 mTLS 模式更改为 `PERMISSIVE`，并确认 Ambient Pod
可以再次接受非 mTLS 连接，包括本例中来自非网状 Pod 的连接。

{{< text bash >}}
$ kubectl apply -n ambient-demo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: peerauth
spec:
  mtls:
    mode: PERMISSIVE
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl exec deploy/sleep -n client-a  -- curl httpbin.ambient-demo.svc.cluster.local:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

### East-West Istio sidecar proxy pod to ambient mesh pod {#ewside2ambient}
### 东西向 Istio Sidecar 代理 Pod 到 Ambient 网格 Pod  {#ewside2ambient}

This use case is that of seamless East-West traffic interoperability between an Istio pod using a sidecar proxy and an ambient pod within the same mesh.
此用例是使用 Sidecar 代理的 Istio Pod 与同一网格内的
Ambient Pod 之间的无缝东西向流量互操作性。

The same httpbin service from the previous example is used but now add a client to access this service from another namespace which is labeled for sidecar injection. This also works automatically and transparently as shown in the example below. In this case the sidecar proxy running with the client automatically knows to use the HBONE control plane since the destination has been discovered to be an HBONE destination. The user does not need to do any special configuration to enable this.
使用与上一个示例相同的 httpbin 服务，但现在添加一个客户端以从另一个标记为
Sidecar 注入的命名空间访问此服务。这也会自动且透明地工作，如下例所示。
在这种情况下，与客户端一起运行的 Sidecar 代理会自动知道使用 HBONE 控制平面，
因为已发现目的地是 HBONE 目标。用户无需进行任何特殊配置即可启用此功能。

{{< tip >}}
For sidecar proxies to use the HBONE/mTLS signaling option when communicating with ambient destinations, they need to be configured with `ISTIO_META_ENABLE_HBONE` set to true in the proxy metadata. This is automatically set for the user as default in the `MeshConfig` when using the `ambient` profile, hence the user does not need to do anything additional when using this profile.
为了使 Sidecar 代理在与 Ambient 目标通信时使用 HBONE/mTLS 信号选项，
需要在代理元数据中将 `ISTIO_META_ENABLE_HBONE` 设置为 true 进行配置。
使用 `ambient` 配置文件时，会在 `MeshConfig` 中自动为用户设置默认值，
因此用户在使用此配置文件时无需执行任何其他操作。
{{< /tip >}}

{{< text bash >}}
$ kubectl create ns client-b
$ kubectl label namespace client-b istio-injection=enabled
$ kubectl apply -f samples/sleep/sleep.yaml -n client-b
$ kubectl wait --for condition=available  deployment/sleep -n client-b
{{< /text >}}

Wait for the pods to get to Running state in the client-b namespace before continuing.
等待 pod 在 client-b 命名空间中进入 Running 状态，然后再继续。

{{< text bash >}}
$ kubectl exec deploy/sleep -n client-b  -- curl httpbin.ambient-demo.svc.cluster.local:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

Again, it can further be verified from viewing the logs of the ztunnel pod (not shown in the example) at the destination node that traffic does in fact use the HBONE and CONNECT based path from the sidecar proxy based source client pod to the ambient based destination service pod. Additionally not shown but it can also be verified that unlike the previous subsection, in this case even if you apply a `PeerAuthentication` resource to the namespace tagged for ambient mode, communication continues between client and service pods since both use the HBONE control and data planes relying on mTLS.
同样，通过查看目标节点上 ztunnel Pod（示例中未显示）的日志，
可以进一步验证流量实际上确实使用从基于 Sidecar 代理的源客户端 Pod
到基于 Ambient 的基于 HBONE 和 CONNECT 的路径。目标服务吊舱。
另外未显示，但也可以验证与前一小节不同，在这种情况下，即使您将 `PeerAuthentication`
资源应用于标记为 Ambient 模式的命名空间，客户端和服务 Pod 之间的通信也会继续，
因为两者都使用依赖 mTLS 的 HBONE 控制面和数据面。

### North-South Ingress Gateway to ambient backend pods {#nsingress2ambient}
### Ambient 后端 Pod 的南北入口网关  {#nsingress2ambient}

THis section describes a use case for North-South traffic with an Istio Gateway exposing the httpbin service via the Kubernetes Gateway API. The gateway itself is running in a non-Ambient namespace and may be an existing gateway that is also exposing other services that are provided by non-ambient pods. Hence this example shows that ambient workloads can also interoperate with Istio gateways that need not themselves be running in namespaces tagged for ambient mode of operation.
本节介绍了南北流量的用例，其中 Istio 网关通过 Kubernetes Gateway API
公开 httpbin 服务。网关本身在非 Ambient 命名空间中运行，
并且可能是一个现有网关，也公开非 Ambient Pod 提供的其他服务。
因此，此示例表明 Ambient 工作负载还可以与 Istio 网关进行互操作，
而 Istio 网关本身不需要在标记为 Ambient 操作模式的命名空间中运行。

For this example, you can use `metallb` to provide a load balancer service on an IP addresses that is reachable from outside the cluster. The same example also works with other forms of North-South load balancing options. The example below assumes that you have already installed `metallb` in this cluster to provide the load balancer service including a pool of IP addresses for `metallb` to use for exposing services externally. Refer to the [`metallb` guide for kind](https://kind.sigs.k8s.io/docs/user/loadbalancer/) for instructions on setting up `metallb` on kind clusters or refer to the instructions from the [`metallb` documentation](https://metallb.universe.tf/installation/) appropriate for your environment.
对于此示例，您可以使用 `metallb` 在可以从集群外部访问的 IP 地址上提供负载均衡器服务。
同一示例还适用于其他形式的南北负载均衡选项。
下面的示例假设您已经在此集群中安装了 `metallb` 来提供负载均衡器服务，
其中包括 `metallb` 的 IP 地址池，以用于向外部公开服务。
请参阅 [`metallb` kind 指南](https://kind.sigs.k8s.io/docs/user/loadbalancer/)，
了解有关在 kind 集群上设置 `metallb` 的说明，或参阅适用于您的环境的
[`metallb` 文档](https://metallb.universe.tf/installation/)。

This example uses the Kubernetes Gateway API for configuring the N-S gateway. Since this API is not currently provided as default in Kubernetes and kind distributions, you have to install the API CRDs first as shown in the example.
此示例使用 Kubernetes Gateway API 来配置 N-S 网关。
由于 Kubernetes 和 kind 发行版中当前未默认提供此 API，
因此您必须首先安装 API CRD，如示例中所示。

An instance of `Gateway` using the Kubernetes Gateway API CRDs will then be deployed to leverage this `metallb` load balancer service. The instance of Gateway runs in the istio-system namespace in this example to represent an existing Gateway running in a non-ambient namespace. Finally an `HTTPRoute` will be provisioned with a backend reference pointing to the existing httpbin service that is running on an ambient pod in the ambient-demo namespace.
然后，将部署使用 Kubernetes Gateway API CRD 的 `Gateway` 实例，
以利用此 `metallb` 负载均衡器服务。在此示例中，
Gateway 的实例在 istio-system 命名空间中运行，表示在非 Ambient
命名空间中运行的现有网关。最后，将为 `HTTPRoute` 配置一个后端引用，
该引用指向在 ambient-demo 命名空间中的 Ambient Pod 上运行的现有 httpbin 服务。

{{< text bash >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v0.6.1" | kubectl apply -f -; }
{{< /text >}}

{{< tip >}}
{{< boilerplate gateway-api-future >}}
{{< boilerplate gateway-api-choose >}}
{{< /tip >}}

{{< text bash >}}
$ kubectl apply -f - << EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: httpbin-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl apply -n ambient-demo -f - << EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: httpbin-gateway
    namespace: istio-system
  rules:
  - backendRefs:
    - name: httpbin
      port: 8000
EOF
{{< /text >}}

Next find the external service IP address on which the Gateway is listening and then access the httpbin service on this IP address (172.18.255.200 in the example below) from outside the cluster as shown below.
接下来找到网关正在侦听的外部服务 IP 地址，
然后从集群外部访问该 IP 地址（下面例中的 172.18.255.200）上的 httpbin 服务，如下所示。

{{< text bash >}}
$ kubectl get service httpbin-gateway-istio -n istio-system
NAME                    TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                        AGE
httpbin-gateway-istio   LoadBalancer   10.110.30.25   172.18.255.200   15021:32272/TCP,80:30159/TCP   121m
{{< /text >}}

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service httpbin-gateway-istio  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ echo "$INGRESS_HOST"
172.18.255.200
{{< /text >}}

{{< text bash >}}
$ curl  "$INGRESS_HOST" -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

These examples illustrate multiple options for interoperability between ambient pods and non-ambient endpoints (which can be either Kubernetes application pods or Istio gateway pods with both Istio native gateways and Kubernetes Gateway API instances). Interoperability is also supported between Istio ambient pods and Istio Egress Gateways as well as scenarios where the ambient pods run the client-side of an application with the service side running outside of the mesh of on a mesh pod that uses the sidecar proxy mode. Hence users have multiple options for seamlessly integrating ambient and non-ambient workloads within the same Istio mesh, allowing for phased introduction of ambient capability as best suits the needs of Istio mesh deployments and operations.
这些示例说明了 Ambient Pod 和非 Ambient 端点（可以是 Kubernetes
应用程序 Pod 或具有 Istio 原生网关和 Kubernetes Gateway API 实例的 Istio 网关 Pod）
之间的互操作性的多种选项。Istio Ambient Pod 和 Istio Egress
网关之间还支持互操作性，以及 Ambient Pod 运行应用程序的客户端且服务端运行在使用
Sidecar 代理模式的网格 Pod 之外的场景。因此，
用户有多种选择可以在同一 Istio 网格中无缝集成 Ambient 和非 Ambient 工作负载，
从而允许以最适合 Istio 网格部署和操作的需求分阶段引入 Ambient 功能。
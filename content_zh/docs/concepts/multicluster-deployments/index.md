---
title: 多集群部署
description: 描述如何配置服务网格以包含来自多个集群的服务。
weight: 60
---

Istio 是一个[服务网格](/zh/docs/concepts/what-is-istio/#什么是服务网格)，其基本属性是监控和管理单个管理域下协作微服务网格的能力。服务网格本质上是将一组单独的微服务组合成单个可控的复合应用程序。

对于特定大小的应用，组成应用程序的所有的微服务都可以在单个编排平台上运行（例如 Kubernetes 集群）。然而，由于诸如规模、冗余等许多原因，大多数应用程序最终将需要分布式设计并使其中的一些服务能够运行在任何地方。

Istio 支持将一个应用程序的服务以多种拓扑分布，而不仅仅是分布在单一集群，例如：

* 集群内部的服务可以使用 [service entry](/zh/docs/concepts/traffic-management/#service-entry) 访问独立的外部服务，或访问其余松散耦合服务网格（或者说是*网格联邦*）公开的服务。
* 您可以[扩展服务网格](/zh/docs/setup/kubernetes/additional-setup/mesh-expansion/)以包含运行在虚拟机或裸金属主机上的服务。
* 您可以将多个集群中的服务组合成一个单一复合服务网格，也即*多集群网格*。

## 多集群服务网格

多集群服务网格是由在多个底层集群中运行的 service 组成的网格，但所有 service 都在单一管控机制下运行。在一个多集群网格中，集群 1 里 namespace `ns1` 下名为 `foo` 的 service 与集群 2 里 `ns1` 下的 `foo` 是同一个 service。与松散耦合的服务网格联邦不同，在联邦中，两个集群对相同 service 的定义可能不同，在集成集群时需要对其进行协调。

多集群网格的好处是所有 service 对客户端看起来都一样，不管工作负载实际上运行在哪里。无论是部署在单个还是多个网格中，它对应用程序都是透明的。要实现此行为，需要使用单个逻辑控制平面管理所有 service。但是，单个逻辑控制平面不一定需要是单个物理 Istio 控制平面。存在两种可能的部署方法：

1. 多个同步的 Istio 控制平面，具有复制的 service 和路由配置。

1. 单个 Istio 控制平面，可以访问和配置网格中的所有 service。

即使在这两种拓扑中，也有多种配置多集群网格的方法。使用哪种方法，以及如何配置取决于应用程序的要求，
以及底层云平台的功能和限制。

### 多控制平面拓扑

在多控制平面配置中，每个集群具有相同的 Istio 控制平面安装方式，每个控制平面管理自己的 endpoint。
使用 Istio gateway、公共根证书颁发机构（CA）和 service entry，您可以配置由参与集群组成的单个逻辑服务网格。这种方法没有特殊的网络要求，因此通常被认为是在集群之间没有通用连接时最简单的方法。

{{< image width="80%" ratio="36.01%"
    link="/docs/concepts/multicluster-deployments/multicluster-with-gateways.svg"
    caption="Istio 网格跨越多个 Kubernetes 集群，使用多个 Istio 控制平面和 Gateway 到达远程 pod"
    >}}

要在集群中实现单个 Istio 服务网格，您需要配置一个公共根 CA 并复制所有集群中共享的 service 和 namespace。跨集群通信发生在各个集群的 Istio 网关上。所有集群都共享策略实施和安全性的控制。

在这个配置中，每个集群中的工作负载都可以像平常一样使用 Kubernetes DNS 后缀们访问其他本地 service，例如`foo.ns1.svc.cluster.local`。为了给远程集群中的 service 提供DNS解析，Istio 包含了 一个 CoreDNS 服务器，此服务器被配置为可以处理 `<name>。<namespace> .global` 形式的 service 名称。例如，从任何集群到 `foo.ns1.global` 的调用将解析到任意集群 namespace `ns1` 中运行的 `foo` service。要进行这种多集群配置，请访问我们提供的[带网关指令的多控制平面](/zh/docs/setup/kubernetes/install/multicluster/gateways/)页面。

### 单一控制平面拓扑

这种多集群配置使用运行在某个集群上的单个 Istio 控制平面。控制平面的 Pilot 管理本地和远程集群上的 service，并为所有集群配置 Envoy sidecar。这种方法在所有参与集群都具有 VPN 连接的环境中效果最佳，从其他任何地方都可以通过相同的 IP 地址访问网格中的每个 pod。

{{< image width="80%" ratio="36.01%"
    link="/docs/concepts/multicluster-deployments/multicluster-with-vpn.svg"
    caption="Istio 网格跨越多个 Kubernetes 集群，通过 VPN 直接访问远程 pod"
    >}}

在此配置中，Istio 控制平面部署在其中一个集群上，而所有其他集群上运行一个更简单的远程 Istio 配置，以将它们连接到单个 Istio 控制平面，该平面将所有 Envoy 作为单个网格进行管理。各个集群上的 IP 地址不得重叠，且需注意远程集群上的 service 的 DNS 解析不是自动的。用户需要在每个参与集群上复制 service。您可以在我们提供的[使用 VPN 指令的单一控制平面](/zh/docs/setup/kubernetes/install/multicluster/vpn/)中找到设置这种多集群拓扑的详细步骤。

如果设置具有全局 pod-to-pod 连接的环境很困难或不可能，您仍然可以使用 Istio 网关并和启用 Istio Pilot 的位置感知服务路由功能（也即`水平分割 EDS（Endpoint Discovery Service，终端发现服务）`）来配置单个控制平面拓扑。此方法仍需要从所有集群到 Kubernetes API server 的连接，例如在一个托管的 Kubernetes 平台上，其 API server 运行的网络可以被所有租户集群访问。如果无法做到这一点，那么多控制平面拓扑可能是更好的选择

{{< image width="80%" ratio="36.01%"
    link="/docs/concepts/multicluster-deployments/multicluster-split-horizon-eds.svg"
    caption="Istio 网格使用单个控制平面和 Gateway 跨越多个 Kubernetes 集群到达远程 pod"
    >}}

在此配置中，从一个集群中的 sidecar 到同一集群中的 service 的请求仍然被转发到本地 service IP。如果目标工作负载在其他集群中运行，远程集群网关 IP 会替代 service 用于连接。访问我们的[单一控制平面](/zh/docs/examples/multicluster/split-horizon-eds/)页面，并使用网关示例来试验此功能。

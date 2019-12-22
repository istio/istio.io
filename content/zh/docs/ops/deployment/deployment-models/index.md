---
title: 部署模型
description: 描述 Istio 部署中的选择和建议。
weight: 20
keywords:
  - single-cluster
  - multiple-clusters
  - control-plane
  - tenancy
  - networks
  - identity
  - trust
  - single-mesh
  - multiple-meshes
aliases:
  - /zh/docs/concepts/multicluster-deployments
  - /zh/docs/concepts/deployment-models
  - /zh/docs/ops/prep/deployment-models
---

当您将 Istio 用于生产环境部署时，需要回答一系列的问题。
网格将被限制在单个 {{< gloss "cluster">}}集群{{< /gloss >}} 中还是分布在多个集群中？
是将所有服务都放置在单个完全连接的网络中，还是需要网关来跨多个网络连接服务？
是否存在单个{{< gloss "control plane">}}控制平面{{< /gloss >}}（可能在集群之间共享），或者是否部署了多个控制平面以确保高可用（HA）？
如果要部署多个集群（更具体地说是在隔离的网络中），是否要将它们连接到单个{{< gloss "multicluster">}}多集群{{< /gloss >}}服务网格中，
还是将它们联合到一个 {{< gloss "multi-mesh">}}多网格{{< /gloss >}} 部署中？

所有这些问题，都代表了 Istio 部署的独立配置维度。

1. 单一或多个集群
1. 单一或多个网络
1. 单一或多控制平面
1. 单一或多个网格

所有组合都是可能的，尽管某些组合比其他组合更常见，并且某些组合显然不是很有趣（例如，单一集群中有多个网格）。

在涉及多个集群的生产环境部署中，部署可能使用多种模式。
例如，基于 3 个集群实现多控制平面的高可用部署，您可以通过使用单一控制平面部署 2 个集群，然后再添加第 3 个集群和
第 2 个控制平面来实现这一点，最后，再将所有 3 个集群配置为共享 2 个控制平面，以确保所有集群都有 2 个控制源来确保 HA。

如何选择正确的部署模型，取决于您对隔离性、性能和 HA 的要求。本指南介绍了配置 Istio 部署时的各种选择和注意事项。

## 集群模型{#cluster-models}

应用程序的工作负载实例运行在一个或多个{{< gloss "cluster" >}}集群{{< /gloss >}}中。
针对隔离性、性能和高可用的需求，您还可以将集群限制在可用区和地域中。

根据需求，生产系统可以跨多个集群（基于多可用区、多地域）运行，
借助云负载均衡器来处理诸如本地、区域或地域性故障转移之类的问题。

大多数情况下，集群代表着配置和端点发现的边界。
例如，每个 Kubernetes 集群都有一个 API 服务器，该服务器管理集群的配置，
在 Pod 变化时提供 {{< gloss "service endpoint">}}服务端点{{< /gloss >}} 信息。
Kubernetes 在每个集群都默认配置此行为，这有助于限制由错误配置引起的潜在风险。

在 Istio 中，您可以配置单一服务网格以跨越任意数量的集群。

### 单一集群{#single-cluster}

在最简单的情况下，您可以将 Istio 网格限制为单一{{< gloss "cluster" >}}集群{{< /gloss >}}。
集群通常在[单一网络](#single-network)上运行，但是在不同的基础架构之间会有所不同。
单一集群和单一网络模型包括一个控制平面，这是最简单的 Istio 部署。

{{< image width="50%"
    link="single-cluster.svg"
    alt="单一集群服务网格"
    title="单一集群"
    caption="单一集群服务网格"
    >}}

单一集群部署提供了简单性，但缺少更多的功能，例如，故障隔离和故障转移。
如果您需要高可用性，则应使用多个集群。

### 多集群{#multiple-clusters}

您可以将单个网格配置为包括多{{< gloss "cluster" >}}集群{{< /gloss >}}。
在单一网格中使用{{< gloss "multicluster">}}多集群{{< /gloss >}}部署，与单一集群部署相比其具备以下更多能力：

- 故障隔离和故障转移：当 `cluster-1` 下线，业务将转移至 `cluster-2`。
- 位置感知路由和故障转移：将请求发送到最近的服务。
- 多种[控制平面](#control-plane-models)模型：支持不同级别的可用性。
- 团队或项目隔离：每个团队仅运行自己的集集群。

{{< image width="75%"
    link="multi-cluster.svg"
    alt="多集群服务网格"
    title="多集群"
    caption=多集群服务网格"
    >}}

多集群部署可为您提供更大程度的隔离和可用性，但会增加复杂性。
如果您的系统具有高可用性要求，则可能需要集群跨多个可用区和地域。
对于应用变更或新的版本，您可以在一个集群中配置金丝雀发布，这有助于把对用户的影响降到最低。
此外，如果某个集群有问题，您可以暂时将流量路由到附近的集群，直到解决该问题为止。

您可以根据[网络](#network-models)和云提供商所支持的选项来配置集群间通信。
例如，若两个集群位于同一基础网络，则可以通过简单地配置防火墙规则来启用跨集群通信。

## 网络模型{#network-models}

许多生产系统需要多个网络或子网来实现隔离和高可用性。
Istio 支持跨多种网络拓扑扩展服务网格。
这使您可以选择适合您现有网络拓扑的网络模型。

### 单一网络{#single-network}

在最简单的情况下，服务网格在单个完全连接的网络上运行。
在单一网络模型中， {{< gloss "workload instance" >}}工作负载实例{{< /gloss >}}
都可以直接相互访问，而无需 Istio 网关。

单一网络模型允许 Istio 以统一的方式在网格上配置服务使用者，从而能够直接处理工作负载实例。

{{< image width="50%"
    link="single-net.svg"
    alt="单一网络服务网格"
    title="单一网络"
    caption="单一网络服务网格"
    >}}

### 多网络{#multiple-networks}

您可以配置单个服务网格跨多个网络，这样的配置称为**多网络**。

多网络模型提供了单一网络之外的以下功能：

- **服务端点**范围的 IP 或 VIP 重叠
- 跨越管理边界
- 容错能力
- 网络地址扩展
- 符合网络分段要求的标准

在此模型中，不同网络中的工作负载实例只能通过一个或多个 Istio 网关相互访问。Istio 使用 **分区服务发现** 为消
费者提供 {{< gloss "service endpoint">}}服务端点{{< /gloss >}} 的不同视图。该视图取决于消费者的网络。

{{< image width="50%"
    link="multi-net.svg"
    alt="多网络服务网格"
    title="多网络部署"
    caption="多网络服务网格"
    >}}

## 控制平面模型{#control-plane-models}

Istio 网格使用{{< gloss "control plane">}}控制平面{{< /gloss >}}来配置网格内工作负载实例之间的所有通信。
您可以复制控制平面，工作负载实例可以连接到任何一个控制平面实例以获取其配置。

在最简单的情况下，可以在单一集群上使用控制平面运行网格。

{{< image width="50%"
    link="single-cluster.svg"
    alt="单一控制平面服务网格"
    title="单一控制平面"
    caption="单一控制平面服务网格"
    >}}

多集群部署也可以共享控制平面实例。在这种情况下，控制平面实例可以驻留在一个或多个集群中。

{{< image width="75%"
    link="shared-control.svg"
    alt="跨两个集群共享控制平面的服务网格"
    title="共享控制平面"
    caption="跨两个集群共享控制平面的服务网格"
    >}}

为了获得高可用性，您应该在多个集群、区或地域之间部署控制平面。

{{< image width="75%"
    link="multi-control.svg"
    alt="每个地域都有控制平面实例的服务网格"
    title="多控制平面"
    caption="每个地域都有控制平面实例的服务网格"
    >}}

该模型具有以下优点：

- 更强的可用性：如果控制平面不可用，则中断范围仅限于该控制平面。

- 配置隔离：您可以在一个集群、区域或地域中进行配置更改，而不会影响其他集群、区或或地域。

您可以通过故障转移来提高控制平面的可用性。当控制平面实例不可用时，工作负载实例可以连接到另一个可用的控制平面实例。
故障转移可能发生在集群、区域或地域之间。

{{< image width="50%"
    link="failover.svg"
    alt="控制平面实例失败后的服务网格"
    title="控制平面故障转移"
    caption="控制平面实例失败后的服务网格"
    >}}

以下列表按可用性对控制平面部署进行了排名：

- 每个地域一个集群（**最低可用性**）
- 每个地域多个集群
- 每个区域一个集群
- 每个区域多个集群
- 每个集群（**最高可用性**）

## 身份和信任模型{#identity-and-trust-models}

在服务网格中创建工作负载实例时，Istio 会为工作负载分配一个{{< gloss "identity">}}身份标识{{< /gloss >}}。

证书颁发机构（CA）创建并签名身份标识的证书，以用于验证网格中的使用者身份，您可以使用其公钥来验证消息发送者的身份。
**trust bundle** 是一组在 Istio 网格使用的所有 CA 公钥的集合。使用 **trust bundle** 任何人都可以验证来自该网格的任何消息发送者。

### 网格内的信任{#trust-within-a-mesh}

在单一 Istio 网格中，Istio 确保每个工作负载实例都有一个表示自己身份的适当证书，以及用于识别网格及网格联邦中所有身份
信息的 **trust bundle**。CA 只为这些身份标识创建和签名证书。该模型允许网格中的工作负载实例通信时相互认证。

{{< image width="50%"
    link="single-trust.svg"
    alt="具有证书颁发机构的服务网格"
    title="网格内的信任模型"
    caption="具有证书颁发机构的服务网格"
    >}}

### 网格之间的信任{#trust-between-meshes}

如果网格中的服务需要另一个网格中的服务，则必须在两个网格之间联合身份和信任。要在不同网格之间联合身份和信任，必须交换网格的 **trust bundle**。
您可以使用像 [SPIFFE 信任域联邦](https://docs.google.com/document/d/1OC9nI2W04oghhbEDJpKdIUIw-G23YzWeHZxwGLIkB8k/edit)
之类的协议手动或自动交换 **trust bundle**，将 **trust bundle** 导入网格后，即可为这些身份配置本地策略。

{{< image width="50%"
    link="multi-trust.svg"
    alt="具有证书颁发机构的多服务网格"
    title="网格之间的信任模型"
    caption="具有证书颁发机构的多服务网格"
    >}}

## 网格模型{#mesh-models}

Istio 支持将您的所有服务都放在一个{{< gloss "service mesh" >}}服务网格{{< /gloss >}}中，
或者将多个网格联合在一起，这也称为{{< gloss "multi-mesh">}}多网格{{< /gloss >}}。

### 单一网格{#single-mesh}

最简单的 Istio 部署是单一网格。网格内，服务名称是唯一的。例如，在命名空间 `foo` 中只能存在一个名为 `mysvc` 的服务。
此外，工作负载实例具有相同的标识，因为服务帐户名称在命名空间中也是唯一的，就像服务名称一样。

单一网格可以跨越[一个或多个集群](#cluster-models)和[一个或多个网络](#network-models)。
网格内部，[命名空间](#namespace-tenancy)用于[多租户](#tenancy-models)。

### 多网格{#multiple-meshes}

通过{{< gloss "mesh federation">}}网格联邦{{< /gloss >}}可以实现多网格部署。

与单一网格相比，多网格具备以下更多功能：

- 组织边界：业务范围
- 服务名称或命名空间复用：比如 `default` 的使用
- 加强隔离：将测试工作负载与生产工作负载隔离

您可以使用{{< gloss "mesh federation">}}网格联邦{{</gloss >}}启用网格间通信。
联合时，每个网格可以公开一组服务和身份，它们可以被所有参与的网格都可以识别。

{{< image width="50%"
    link="multi-mesh.svg"
    alt="多服务网格"
    title="多服务网格"
    caption="多服务网格"
    >}}

为避免服务命名冲突，可以为每个网格赋予全局唯一的 **mesh ID**，以确保每个服务的完全限定域名（FQDN）是不同的。

联合两个不共享同一{{< gloss "trust domain">}}信任域{{< /gloss >}}的网格时， 必须{{< gloss "mesh federation">}}
联合{{< /gloss >}}身份标识和它们之间的 **trust bundles**。有关概述请参考[多信任域](#trust-between-meshes)部分。

## 租户模型{#tenancy-models}

在 Istio 中，**租户**是一组用户，它们共享对一组已部署工作负载的公共访问权限。通常，您可以通过网络配置和策略将工作负载实例与多个租户彼此隔离。

您可以配置租户模型以满足以下组织隔离要求：

- 安全
- 策略
- 容量(Capacity)
- 成本(Cost)
- 性能

Istio 支持两种类型的租赁模型：

- [命名空间租赁](#namespace-tenancy)
- [集群租赁](#cluster-tenancy)

### 命名空间租赁{#namespace-tenancy}

Istio 使用[命名空间](https://kubernetes.io/docs/reference/glossary/?fundamental=true#term-namespace)作为网格内的租赁单位。
Istio 还可以在未实现命名空间租用的环境中使用。在这样的环境中，您可以授予团队权限，以仅允许其将工作负载部署到给定的或一组命名空间。
默认情况下，来自多个租赁命名空间的服务可以相互通信。

{{< image width="50%"
    link="iso-ns.svg"
    alt="具有两个隔离的命名空间的服务网格"
    title="独立命名空间"
    caption="具有两个隔离的命名空间的服务网格"
    >}}

为提高隔离性，您可以有选择地将部分服务公开给其他命名空间。您可以为公开服务配置授权策略，以将访问权限仅交给适当的调用者。

{{< image width="50%"
    link="exp-ns.svg"
    alt="具有两个命名空间和一个公开服务的服务网格"
    title="具有两个命名空间和一个公开服务的服务网格"
    caption="具有两个命名空间和一个公开服务的服务网格"
    >}}

在[多集群](#multiple-clusters)场景中，不同集群中名字相同的命名空间，被认为是相同的命名空间。
例如，集群 `cluster-1` 中命名空间 `foo` 下的服务 `Service B` 与集群 `cluster-2` 中命名空间 `foo` 下的服务 `Service B`，
指向的是相同的服务，Istio 会合并这些服务端点，用于服务发现和负载均衡。

{{< image width="50%"
    link="cluster-ns.svg"
    alt="具有相同命名空间的多集群服务网格"
    title="多集群命名空间"
    caption="具有相同命名空间的多集群服务网格"
    >}}

### 集群租户模型{#cluster-tenancy}

Istio 还支持使用集群作为租赁单位。在这种情况下，您可以为每个团队提供一个专用集群或一组集群来部署其工作负载。
集群的权限通常仅限于拥有它的团队和成员。您可以设置各种角色以实现更精细的控制，例如：

- 集群管理员
- 开发者

要在 Istio 中使用集群租用，请将每个集群配置为一个独立的网格。或者，您可以使用 Istio 将一组集群实现为单一租户。
然后，每个团队可以拥有一个或多个集群，但是您可以将所有集群配置为单一网格。
要将各个团队的网格连接在一起，可以将网格联合成一个多网格部署。

{{< image width="50%"
    link="cluster-iso.svg"
    alt="具有两个集群和两个命名空间的隔离的服务网格"
    title="集群隔离"
    caption="具有两个集群和两个命名空间的隔离的服务网格"
    >}}

由于每个网格都由不同的团队或组织来管理，因此服务命名不需要担心冲突。
例如，集群 `cluster-1` 中命名空间 `foo` 下的服务 `mysvc` 与集群 `cluster-2` 中命名空间 `foo` 下的服务 `mysvc`，
不是指相同的服务。最常见的示例是在 Kubernetes 中的场景，其中许多团队将其工作负载部署到 `default` 命名空间。

当每个团队都有自己的网格时，跨网格通信遵循[多网格模型](#multiple-meshes)中描述的概念。

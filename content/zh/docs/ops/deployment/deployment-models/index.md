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
owner: istio/wg-environments-maintainers
test: n/a
---

当您将 Istio 用于生产环境部署时，需要确定一系列的问题。
网格将被限制在单个{{< gloss "cluster">}}集群{{< /gloss >}}中还是分布在多个集群中？
是将所有服务都放置在单个完全连接的网络中，还是需要网关来跨多个网络连接服务？
是否存在单个{{< gloss "control plane">}}控制平面{{< /gloss >}}（可能在集群之间共享），
或者是否部署了多个控制平面以确保高可用（HA）？
如果要部署多个集群（更具体地说是在隔离的网络中），
是否要将它们连接到单个{{< gloss "multicluster">}}多集群{{< /gloss >}}服务网格中，
还是将它们联合到一个{{< gloss "multi-mesh">}}多网格{{< /gloss >}} 部署中？

所有这些问题，都代表了 Istio 部署的独立配置维度。

1. 单一或多个集群
1. 单一或多个网络
1. 单一或多控制平面
1. 单一或多个网格

所有组合都是可能的，尽管某些组合比其他组合更常见，并且某些组合显然不是很有趣（例如，单一集群中有多个网格）。

在涉及多个集群的生产环境部署中，部署可能使用多种模式。
例如，基于 3 个集群实现多控制平面的高可用部署，您可以通过使用单一控制平面部署 2 个集群，
然后再添加第 3 个集群和第 2 个控制平面来实现这一点，最后，
再将所有 3 个集群配置为共享 2 个控制平面，以确保所有集群都有 2 个控制源来确保 HA。

如何选择正确的部署模型，取决于您对隔离性、性能和 HA 的要求。
本指南介绍了配置 Istio 部署时的各种选择和注意事项。

## 集群模型{#cluster-models}

应用程序的工作负载实例运行在一个或多个{{< gloss "cluster" >}}集群{{< /gloss >}}中。
针对隔离性、性能和高可用的需求，您还可以将集群限制在可用区和地域中。

根据需求，生产系统可以跨多个集群（基于多可用区、多地域）运行，
借助云负载均衡器来处理诸如本地、区域或地域性故障转移之类的问题。

大多数情况下，集群代表着配置和端点发现的边界。
例如，每个 Kubernetes 集群都有一个 API 服务器，该服务器管理集群的配置，
在 Pod 变化时提供{{< gloss "service endpoint">}}服务端点{{< /gloss >}}信息。
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
在单一网格中使用{{< gloss "multicluster">}}多集群{{< /gloss >}}部署，
与单一集群部署相比其具备以下更多能力：

- 故障隔离和故障转移：当 `cluster-1` 下线，业务将转移至 `cluster-2`。
- 位置感知路由和故障转移：将请求发送到最近的服务。
- 多种[控制平面](#control-plane-models)模型：支持不同级别的可用性。
- 团队或项目隔离：每个团队仅运行自己的集群。

{{< image width="75%"
    link="multi-cluster.svg"
    alt="多集群服务网格"
    title="多集群"
    caption="多集群服务网格"
    >}}

多集群部署可为您提供更大程度的隔离和可用性，但会增加复杂性。
如果您的系统具有高可用性要求，则可能需要集群跨多个可用区和地域。
对于应用变更或新的版本，您可以在一个集群中配置金丝雀发布，这有助于把对用户的影响降到最低。
此外，如果某个集群有问题，您可以暂时将流量路由到附近的集群，直到解决该问题为止。

您可以根据[网络](#network-models)和云提供商所支持的选项来配置集群间通信。
例如，若两个集群位于同一基础网络，则可以通过简单地配置防火墙规则来启用跨集群通信。

在多集群网格中，所有的服务都是默认共享的，根据{{< gloss "namespace sameness" >}}命名空间一致性{{< /gloss >}}的概念。
[流量管理规则](/zh/docs/ops/configuration/traffic-management/multicluster)对多集群的流量提供了细粒度的控制。

### 多集群的 DNS {#dns-with-multiple-clusters}

当客户端应用程序向某个主机发出请求时，它必须首先对主机名执行
DNS 查找以获得 IP 地址，然后才能继续请求。
在 Kubernetes 中，集群内的 DNS
服务器通常会根据配置的 `Service` 定义来处理此 DNS 查找。

Istio 使用 DNS 查找返回的虚拟 IP
在所请求 Service 的活动 Endpoint 列表之间进行负载平衡，
同时考虑任何 Istio 配置的路由规则。
Istio 使用 Kubernetes 的 `Service`/`Endpoint`
或 Istio 的 `ServiceEntry` 来配置主机名到工作负载 IP 地址的内部映射。

当您有多个集群时，这种两层命名系统会变得更加复杂。
Istio 本质上是多集群感知的，但 Kubernetes 不是（至少现在不是）。
因此，客户端集群必须具有该 Service 的 DNS 条目，
以便 DNS 查找成功，并成功发送请求。
即使在客户端集群中没有运行该服务的 Pod 实例也是如此。

为确保 DNS 查找成功，您必须将 Kubernetes `Service`
部署到使用该 `Service` 的每个集群。
这确保无论请求来自何处，它都会通过 DNS 查找并交给 Istio 以进行正确的路由。
这也可以通过 Istio `ServiceEntry` 而不是 Kubernetes `Service` 来实现。
但是，`ServiceEntry` 不会配置 Kubernetes DNS 服务器。
这意味着需要手动或使用自动化工具配置 DNS，
例如 [DNS 代理](/zh/docs/ops/configuration/traffic-management/dns-proxy/#address-auto-allocation)
的[自动分配地址](/zh/docs/ops/configuration/traffic-management/dns-proxy/)功能。

{{< tip >}}
正在进行的一些工作将有助于简化 DNS 故事：

- [DNS 边车代理](/zh/blog/2020/dns-proxy/)在 Istio 1.8 中支持预览。这为带有 Sidecar
  的所有工作负载提供 DNS 拦截，允许 Istio 代表应用程序执行 DNS 查找。

- [Admiral](https://github.com/istio-ecosystem/admiral)
  是一个 Istio 社区项目，提供了许多多集群功能。
  如果您需要支持多网络拓扑，那么大规模跨多个集群管理此配置是一项挑战。
  Admiral 对此配置持主观看法，并提供跨集群的自动配置和同步。

- [Kubernetes 多集群 Service](https://github.com/kubernetes/enhancements/tree/master/keps/sig-multicluster/1645-multi-cluster-services-api)
  是一个 Kubernetes 增强提案（KEP），它定义了一个用于将 Service 导出到多个集群的 API。
  这有效地将整个“集群集”的服务可见性和 DNS
  解析的责任推给了 Kubernetes。 还在 Istio 中构建
  `MCS` 支持层的工作正在进行中，这将允许 Istio 与任何云供应商的
  `MCS` 控制器一起工作，甚至充当整个网格的 `MCS` 控制器。
{{< /tip >}}

## 网络模型{#network-models}

Istio 使用网络的简化定义来指代具有直接可达性的工作负载实例。
例如，默认情况下，单个集群中的所有工作负载实例都在同一网络上。

许多生产系统需要多个网络或子网来实现隔离和高可用性。
Istio 支持跨多种网络拓扑扩展服务网格。
这使您可以选择适合您现有网络拓扑的网络模型。

### 单一网络{#single-network}

在最简单的情况下，服务网格在单个完全连接的网络上运行。
在单一网络模型中，
{{< gloss "workload instance" >}}工作负载实例{{< /gloss >}}都可以直接相互访问，
而无需 Istio 网关。

单一网络模型允许 Istio 以统一的方式在网格上配置服务使用者，
从而能够直接处理工作负载实例。

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

在此模型中，不同网络中的工作负载实例只能通过一个或多个
[Istio 网关](/zh/docs/concepts/traffic-management/#gateways)相互访问。
Istio 使用**分区服务发现**为消费者提供{{< gloss "service endpoint">}}服务端点{{< /gloss >}}的不同视图。
该视图取决于消费者的网络。

{{< image width="50%"
    link="multi-net.svg"
    alt="多网络服务网格"
    title="多网络部署"
    caption="多网络服务网格"
    >}}

此解决方案需要通过网关公开所有服务（或子集）。
云供应商可能会提供不需要在公共互联网上公开服务的选项。
这样的选项，如果存在并且满足您的要求，可能是最佳选择。

{{< tip >}}
为了保证多网络场景下的安全通信，Istio 只支持使用 Istio
代理的工作负载进行跨网络通信。
这是因为 Istio 通过 TLS 透传在 Ingress Gateway 公开服务，
这使得 mTLS 直接用于工作负载。
然而，没有 Istio 代理的工作负载可能无法参与与其他工作负载的相互身份验证。
出于这个原因，Istio 过滤了无代理服务的网络外端点。
{{< /tip >}}

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

像这样的集群，具有自己的本地控制平面，被称为{{< gloss "primary cluster" >}}主集群{{< /gloss >}}。

多集群部署还可以共享控制平面实例。在这种情况下，控制平面实例可以驻留在一个或多个集群中。
没有自己的控制平面的集群被称为{{< gloss "remote cluster" >}}从集群{{< /gloss >}}。

{{< image width="75%"
    link="shared-control.svg"
    alt="跨两个集群共享控制平面的服务网格"
    title="共享控制平面"
    caption="跨两个集群共享控制平面的服务网格"
    >}}

为了支持多集群网格中的从集群，主集群中的控制平面必须可以通过稳定的
IP（例如集群 IP）访问。
对于跨网络的集群，这可以通过 Istio 网关公开控制平面来实现。
云供应商可能会提供选项，例如内部负载均衡器，
以在不将控制平面暴露在公共互联网上的情况下提供此功能。
这样的选项，如果存在并且满足您的要求，将可能是最佳选择。

在具有多个主集群的多集群部署中，每个主集群都从驻留在同一集群中的
Kubernetes API 服务器接收其配置（即 `Service` 和 `ServiceEntry`、
`DestinationRule` 等）。因此，每个主集群都有一个独立的配置源。
这种跨主集群的配置重复在推出更改时确实需要额外的步骤。
大型生产系统可以使用工具（例如 CI/CD 系统）自动执行此过程，以便管理配置推出。

完全由从集群组成的服务网格由外部控制平面控制，
而不是在网格内的主要集群中运行控制平面。
这提供了隔离管理，并将控制平面部署与构成网格的数据平面服务完全分离。

{{< image width="100%"
    link="single-cluster-external-control-plane.svg"
    alt="具有外部控制平面的单个集群"
    title="外部控制平面"
    caption="具有外部控制平面的单个集群"
    >}}

云供应商的托管控制平面是外部控制平面的典型示例。

为了获得高可用性，您应该在多个集群、区或地域之间部署控制平面。

{{< image width="75%"
    link="multi-control.svg"
    alt="每个地域都有控制平面实例的服务网格"
    title="多控制平面"
    caption="每个地域都有控制平面实例的服务网格"
    >}}

该模型具有以下优点：

- 更强的可用性：如果控制平面不可用，则不可用范围仅限于该控制平面。
- 配置隔离：您可以在一个集群、区域或地域中进行配置更改，而不会影响其他集群、区或或地域。
- 受控推出：您可以更细粒度地控制配置推出（例如，一次一个集群）。
- 选择性服务可见：您可以将服务可见性限制在网格的一部分，
  帮助建立服务级别隔离。例如，管理员可以选择将 “HelloWorld” 服务部署到集群 A，
  而不是集群 B。任何从集群 B 调用 “HelloWorld” 的尝试都将导致 DNS 查找失败。

以下列表按可用性对控制平面部署进行了排名：

- 每个地域一个集群（**最低可用性**）
- 每个地域多个集群
- 每个区域一个集群
- 每个区域多个集群
- 每个集群（**最高可用性**）

### 多控制平面的端点发现{#endpoint-discovery-with-multiple-control-planes}

Istio 控制平面通过为每个代理提供服务端点列表来管理网格内的流量。
为了使其在多集群场景中工作，每个控制平面都必须观察来自每个集群中 API 服务器的端点。

为了启用集群的端点发现，管理员生成一个 `remote secret` 并将其部署到网格中的每个主集群。
`remote secret` 包含凭据，授予对集群中 API 服务器的访问权限。

然后，控制平面将连接并发现集群的服务端点，从而为这些服务启用跨集群负载平衡。

{{< image width="75%"
    link="endpoint-discovery.svg"
    caption="Primary clusters with endpoint discovery"
    >}}

默认情况下，Istio 将在每个集群的端点之间均匀地负载均衡请求。
在跨越地理区域的大型系统中，
可能需要使用[地域负载均衡](/zh/docs/tasks/traffic-management/locality-load-balancing)让流量保持在同一区域或地区。

在某些高级场景中，可能不需要跨集群的负载平衡。
例如，在蓝/绿部署中，您可以将不同版本的系统部署到不同的集群。
在这种情况下，每个集群都作为一个独立的网格有效运行。
这种行为可以通过几种方式实现：

- 不要在集群之间交换远程密钥，这提供了集群之间最强的隔离。
- 使用 `VirtualService` 和 `DestinationRule` 禁止在两个版本的服务之间进行路由。

在任意情况下，都应阻止跨集群负载平衡。
可以使用外部负载均衡器将外部流量路由到一个集群或另一个集群。

## 身份和信任模型{#identity-and-trust-models}

在服务网格中创建工作负载实例时，Istio 会为工作负载分配一个{{< gloss "identity">}}身份标识{{< /gloss >}}。

证书颁发机构（CA）创建并签名身份标识的证书，以用于验证网格中的使用者身份，
您可以使用其公钥来验证消息发送者的身份。
**trust bundle** 是一组在 Istio 网格使用的所有 CA 公钥的集合。
使用 **trust bundle** 任何人都可以验证来自该网格的任何消息发送者。

### 网格内的信任{#trust-within-a-mesh}

在单一 Istio 网格中，Istio 确保每个工作负载实例都有一个表示自己身份的适当证书，
以及用于识别网格及网格联邦中所有身份信息的 **trust bundle**。
CA 只为这些身份标识创建和签名证书。该模型允许网格中的工作负载实例通信时相互认证。

{{< image width="50%"
    link="single-trust.svg"
    alt="具有证书颁发机构的服务网格"
    title="网格内的信任模型"
    caption="具有证书颁发机构的服务网格"
    >}}

### 网格之间的信任{#trust-between-meshes}

如果网格中的服务需要另一个网格中的服务，则必须在两个网格之间联合身份和信任。
要在不同网格之间联合身份和信任，必须交换网格的 **trust bundle**。
您可以使用像 [SPIFFE 信任域联邦](https://github.com/spiffe/spiffe/blob/main/standards/SPIFFE_Federation.md)
之类的协议手动或自动交换 **trust bundle**，将 **trust bundle**
导入网格后，即可为这些身份配置本地策略。

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

最简单的 Istio 部署是单一网格。网格内，服务名称是唯一的。例如，
在命名空间 `foo` 中只能存在一个名为 `mysvc` 的服务。
此外，工作负载实例具有相同的标识，因为服务帐户名称在命名空间中也是唯一的，
就像服务名称一样。

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

联合两个不共享同一{{< gloss "trust domain">}}信任域{{< /gloss >}}的网格时，必须{{< gloss "mesh federation">}}
联合{{< /gloss >}}身份标识和它们之间的 **trust bundles**。有关概述请参考[多信任域](#trust-between-meshes)部分。

## 租户模型{#tenancy-models}

在 Istio 中，**租户**是一组用户，它们共享对一组已部署工作负载的公共访问权限。
通常，您可以通过网络配置和策略将工作负载实例与多个租户彼此隔离。

您可以配置租户模型以满足以下组织隔离要求：

- 安全
- 策略
- 容量(Capacity)
- 成本(Cost)
- 性能

Istio 支持两种类型的租赁模型：

- [命名空间租赁](#namespace-tenancy)
- [集群租赁](#cluster-tenancy)
- [网格租赁](#mesh-tenancy)

### 命名空间租赁{#namespace-tenancy}

Istio 使用 [命名空间](https://kubernetes.io/zh-cn/docs/reference/glossary/?fundamental=true#term-namespace) 作为网格内的租赁单位。
Istio 还可以在未实现命名空间租用的环境中使用。在这样的环境中，您可以授予团队权限，以仅允许其将工作负载部署到给定的或一组命名空间。
默认情况下，来自多个租赁命名空间的服务可以相互通信。

{{< image width="50%"
    link="iso-ns.svg"
    alt="具有两个隔离的命名空间的服务网格"
    title="独立命名空间"
    caption="具有两个隔离的命名空间的服务网格"
    >}}

为提高隔离性，您可以有选择地将部分服务公开给其他命名空间。
您可以为公开服务配置授权策略，以将访问权限仅交给适当的调用者。

{{< image width="50%"
    link="exp-ns.svg"
    alt="具有两个命名空间和一个公开服务的服务网格"
    title="具有两个命名空间和一个公开服务的服务网格"
    caption="具有两个命名空间和一个公开服务的服务网格"
    >}}

命名空间租赁可以扩展到单个集群之外。
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

要在 Istio 中使用集群租用，
您需要为每个团队的集群配置自己的{{< gloss "control plane" >}}控制平面{{< /gloss >}}，
允许每个团队管理自己的配置。
或者，您可以使用 Istio 将一组集群实现为单个租户，
使用{{< gloss "remote cluster" >}}从集群{{< /gloss >}}或多个同步的{{< gloss "primary cluster" >}}主集群{{< /gloss >}}。
有关详细信息，请参阅[控制平面模型](#control-plane-models)。

### 网格租赁{#mesh-tenancy}

在具有网格联邦的多网格部署中，每个网格都可以用作隔离单元。

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

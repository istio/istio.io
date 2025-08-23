---
title: Ambient 模式的多集群支持介绍（Alpha 版）
description: Istio 1.27 增加了 Alpha 版 Ambient 多集群支持，扩展了熟知的 Ambient 轻量级模块化架构，以提供跨集群的安全连接、发现和负载均衡。
date: 2025-08-04
attribution: Jackie Maertens (Microsoft), Keith Mattix (Microsoft), Mikhail Krinkin (Microsoft), Steven Jin (Microsoft); Translated by Wilson Wu (DaoCloud)
keywords: [ambient,multicluster]
---

多集群一直是 Ambient 模式中呼声最高的功能之一，从 Istio 1.27 开始，
它已进入 Alpha 阶段！我们力求在保留 Ambient 用户喜爱的模块化设计的同时，
充分利用多集群架构的优势，避免其复杂性。此版本带来了多集群网格的核心功能，
并为即将发布的版本中更丰富的功能奠定了基础。

## 多集群的强大功能和复杂性 {#the-power---complexity-of-multicluster}

多集群架构可以提高故障恢复能力，缩小影响范围，并实现跨数据中心的扩展。
然而，集成多个集群会带来连接性、安全性和运维方面的挑战。

在单个 Kubernetes 集群中，每个 Pod 都可以通过唯一的 Pod IP 或服务 VIP 直接连接到另一个 Pod。
但在多集群架构中，这些保证就失效了；不同集群的 IP 地址空间可能会重叠，
即使没有重叠，底层基础架构也需要进行配置以路由跨集群流量。

跨集群连接也带来了安全挑战。Pod 之间的流量会超出集群边界，
Pod 也会接受来自集群外部的连接。如果没有集群边缘的身份验证和强加密，
外部攻击者可能会利用易受攻击的 Pod 或拦截未加密的流量。

多集群解决方案必须安全地连接集群，并通过简单的声明性 API 来实现，
这些 API 可以跟上频繁添加和删除集群的动态环境。

## 关键组件 {#key-components}

Ambient 多集群是基于 Ambient 的扩展，新增了组件并精简了 API，
以便使用 Ambient 的轻量级模块化架构安全地连接集群。
它基于{{< gloss "namespace sameness" >}}命名空间相同性{{< /gloss >}}模型构建，
因此服务可以在不同集群之间保留其现有的 DNS 名称，让您无需更改应用代码即可控制跨集群通信。

### 东西向网关 {#east-west-gateways}

每个集群都有一个东西向网关，该网关具有全局可路由的 IP 地址，
作为跨集群通信的入口点。ztunnel 连接到远程集群的东西向网关，
并通过其命名空间名称识别目标服务。然后，东西向网关将连接负载均衡到本地 Pod。
使用东西向网关的可路由 IP 地址无需进行集群间路由配置，
而使用命名空间名称而非 IP 地址寻址 Pod 则消除了 IP 空间重叠的问题。
这些设计选择共同实现了跨集群连接，即使在添加或删除集群时也无需更改集群网络或重启工作负载。

### 双倍 HBONE {#double-hbone}

Ambient 多集群使用嵌套的 [HBONE](/zh/docs/ambient/architecture/hbone)
连接来高效地保护穿越集群边界的流量。外部 HBONE 连接会加密发往东西向网关的流量，
并允许源 ztunnel 和东西向网关相互验证身份。
内部 HBONE 连接则对流量进行端到端加密，
从而允许源 ztunnel 和目标 ztunnel 相互验证身份。
同时，HBONE 层允许 ztunnel 有效地重用跨集群连接，最大限度地减少 TLS 握手。

{{< image link="./mc-ambient-traffic-flow.png" caption="Istio Ambient 多集群流量" >}}

### 服务发现和范围 {#service-discovery-and-scope}

将服务标记为全局服务可以实现跨集群通信。Istiod 配置东西向网关以接受全局服务流量并将其路由到本地 Pod，
并编程 ztunnel 以将全局服务流量负载均衡到远程集群。

网格管理员通过 `ServiceScope` API 为全局服务定义基于标签的标准，
应用开发者则相应地标记他们的服务。默认的 `ServiceScope` 是：

{{< text yaml >}}
serviceScopeConfigs:
  - servicesSelector:
      matchExpressions:
        - key: istio.io/global
          operator: In
          values: ["true"]
    scope: GLOBAL
{{< /text >}}

这意味着任何带有 `istio.io/global=true` 标签的服务都是全局的。虽然默认值很简单，
但 `ServiceScope` API 可以使用 AND 和 OR 的组合来表达复杂的条件。

默认情况下，ztunnel 会在所有端点（甚至远程端点）之间均匀地进行流量负载均衡，
但可以通过服务的 `trafficDistribution` 字段进行配置，
仅在没有本地端点时才跨越集群边界。因此，用户可以控制流量是否以及何时跨越集群边界，
而无需更改应用程序代码。

## 局限性和路线图 {#limitations-and-roadmap}

尽管当前的 Ambient 多集群实现已具备多集群解决方案的基础功能，
但仍有大量工作要做。我们希望改进以下领域：

* 所有集群的服务和 waypoint 配置必须统一。
* 不支持跨集群 L7 故障转移（L7 策略应用于目标集群）。
* 不支持直接 Pod 寻址或无头服务。
* 仅支持多主部署模型。
* 仅支持每集群单网络部署模型。

我们还希望改进我们的参考文档、指南、测试和性能。

如果您想尝试 Ambient 多集群，请遵循[本指南](/zh/docs/ambient/install/multicluster)。
请注意，此功能目前处于 Alpha 测试阶段，尚未准备好投入生产使用。
我们欢迎您提交错误报告、想法、评论和用例——您可以通过
[GitHub](https://github.com/istio/istio) 或
[Slack](https://istio.slack.com/) 联系我们。

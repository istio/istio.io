---
title: 安装多集群
description: 在多个 Kubernetes 集群中以 Ambient 模式安装 Istio 网格。
weight: 40
keywords: [kubernetes,multicluster,ambient]
simple_list: true
content_above: true
test: table-of-contents
owner: istio/wg-environments-maintainers
next: /zh/docs/ambient/install/multicluster/before-you-begin
---

按照本指南安装跨多个{{< gloss "cluster" >}}集群{{< /gloss >}}的
Istio {{< gloss "ambient" >}}Ambient 服务网格{{< /gloss >}}。

## 现状和局限性 {#current-status-and-limitations}

{{< warning >}}
**Ambient 多集群目前处于 Alpha 测试阶段**，存在一些明显的局限性。
此功能正在积极开发中，建议不要在生产环境中使用。
{{< /warning >}}

在继续进行 Ambient 多集群安装之前，了解此功能的当前状态和限制至关重要：

### 支持的配置 {#supported-configurations}

目前，Ambient 多集群仅支持：在继续 Ambient 多集群安装之前，了解此功能的当前状态和限制至关重要。

### 关键限制 {#critical-limitations}

#### 网络拓扑限制 {#network-topology-restrictions}

**多集群单网络配置未经测试，可能会出现问题**
- 在共享同一网络的集群之间部署 Ambient 时要小心
- 仅支持多网络配置

#### 控制平面限制 {#control-plane-limitations}

**目前不支持主集群远程配置**
- 您只能拥有多个主集群
- 具有一个或多个远程集群的配置将无法正常工作

#### waypoint 要求 {#waypoint-requirements}

**假设跨集群部署通用 waypoint**
- 所有集群必须具有相同名称的 waypoint 部署
- waypoint 配置必须跨集群手动同步（例如使用 Flux、ArgoCD 或类似工具）
- 流量路由依赖于一致的 waypoint 命名约定

#### 服务可见性和范围 {#service-visibility-and-scoping}

**服务范围配置无法跨集群读取**
- 仅使用本地集群的服务范围配置作为真实来源
- 不遵循远程集群服务范围，这可能导致意外的流量行为
- 跨集群服务发现可能不遵循预期的服务边界

**如果服务的 waypoint 被标记为全局，则该服务也将是全局的**
- 如果不仔细管理，这可能会导致意外的跨集群流量

#### 网关限制 {#gateway-limitations}

**Ambient 东西网关目前仅支持网格内 mTLS 流量**
- 目前无法使用 Ambient 东西向网关在网络上公开 `istiod`。您仍然可以使用经典的东西向网关来实现此目的。

{{< tip >}}
随着 Ambient 多集群技术的成熟，许多此类限制将得到解决。
请查看 [Istio 发行说明](/zh/news/)，
了解 Ambient 多集群功能的更新。
{{< /tip >}}

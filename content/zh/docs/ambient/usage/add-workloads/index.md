---
title: 将工作负载添加到网格中
description: 了解如何将工作负载添加到 Ambient 网格中。
weight: 10
owner: istio/wg-networking-maintainers
test: no
---

在大多数情况下，集群管理员将部署 Istio 网格基础设施。
一旦支持 Ambient {{< gloss "data plane" >}}数据平面{{< /gloss >}}模式的 Istio 被成功部署，
在配置为可以使用 Istio 的命名空间中，Istio 将完全可用于其中所有用户所部署的应用。

## 为网格中的应用启用 Ambient 模式 {#enabling-ambient-mode-for-an-application-in-the-mesh}

要在 Ambient 模式下将应用或命名空间添加到网格，
请将 `istio.io/dataplane-mode=ambient` 标签添加到相应的资源。
您可以将此标签应用于命名空间或单个 Pod。

就应用 Pod 而言，可以完全透明地无缝启用（或禁用）Ambient 模式。
与 {{< gloss "sidecar" >}}Sidecar{{< /gloss >}} 数据平面模式不同，
无需重启应用即可将它们添加到网格中，并且这些应用不会显示为在其 Pod 中部署了额外的容器。

### Layer 4 和 Layer 7 功能 {#layer-4-and-layer-7-functionality}

安全的 L4 覆盖支持身份验证和鉴权策略。
[了解 Ambient 模式下的 L4 策略支持](/zh/docs/ambient/usage/l4-policy/)。
要选择使用 Istio 的 L7 功能（例如流量路由），
您需要[部署 waypoint 代理并注册您的工作负载](/zh/docs/ambient/usage/waypoint/)。

## 不同数据平面模式下的 Pod 间通信 {#communicating-between-pods-in-different-data-plane-modes}

使用 Ambient 数据平面模式的应用 Pod 与非 Ambient 端点
（包括 Kubernetes 应用 Pod、Istio 网关或 Kubernetes Gateway API 实例）
之间的互操作性有多种选择。这种互操作性用于在同一 Istio 网格中无缝集成
Ambient 和非 Ambient 工作负载提供了多种选项，
从而允许以最适合网格部署和操作的需求分阶段引入 Ambient 功能。

### 网格外的 Pod {#pods-outside-the-mesh}

无论是在 Sidecar 还是 Ambient 模式下，您的命名空间可能根本不是网格的一部分。
在这种情况下，非网格 Pod 直接向目标 Pod 发起流量，而不经过源节点的 ztunnel，
而目标 Pod 的 ztunnel 会强制执行任意 L4 策略来控制是否允许或是拒绝流量。

例如，在启用了 Ambient 模式的命名空间中，将 `PeerAuthentication` 策略的
mTLS 模式设置为 `STRICT` 将导致来自网格外部的流量被拒绝。

### 使用 Sidecar 模式的网格内 Pod {#pods-inside-the-mesh-using-sidecar-mode}

Istio 支持同一网格内带有 Sidecar 的 Pod 和使用 Ambient 模式的 Pod 之间的东西向互操作性。
由于已发现目标是 HBONE 目标，所以 Sidecar 代理知道使用 HBONE 协议。

{{< tip >}}
为了使 Sidecar 代理在与 Ambient 目标通信时使用 HBONE/mTLS 信令选项，
需要在代理元数据中将 `ISTIO_META_ENABLE_HBONE` 配置设置为 `true`。
这是使用 `ambient` 配置文件时 `MeshConfig` 中的默认设置，因此在使用此配置文件时您无需执行任何其他操作。
{{< /tip >}}

`PeerAuthentication` 策略的 mTLS 模式设置为 `STRICT`
时将允许来自具有 Istio Sidecar 代理的 Pod 的流量。

### 入口和出口网关以及 Ambient 模式 Pod {#ingress-and-egress-gateways-and-ambient-mode-pods}

入口网关可以在非 Ambient 命名空间中运行，并暴露由 Ambient 模式、Sidecar 模式或非网格 Pod 提供的服务。
Ambient 模式下的 Pod 与 Istio 出口网关之间也支持互操作性。

## Ambient 模式和 Sidecar 模式的 Pod 选择逻辑 {#pod-selection-logic-for-ambient-and-sidecar-modes}

Istio 的两种数据平面模式，Sidecar 和 Ambient，可以在同一个集群中共存。
确保同一 Pod 或命名空间不会配置为同时使用两种模式非常重要。
但是，如果确实发生这种情况，则当前此类 Pod 或命名空间将优先采用 Sidecar 模式。

请注意，理论上，通过与命名空间标签分开标记各个 Pod，
可以将同一命名空间中的两个 Pod 设置为使用不同的模式；但是，不建议这样做。
对于大多数常见用例，单一模式应用于单个命名空间内的所有 Pod。

确定 Pod 是否设置为使用 Ambient 模式的具体逻辑如下：

1. `cni.values.excludeNamespaces` 中被配置的 `istio-cni` 插件排除列表用于跳过排除列表中的命名空间。
1. Pod 使用 `ambient` 模式，如果：

    * 命名空间或 Pod 具有 `istio.io/dataplane-mode=ambient` 标签
    * Pod 没有选择移除 `istio.io/dataplane-mode=none` 标签
    * Pod 上不存在 `sidecar.istio.io/status` 注解

避免配置冲突的最简单选项是用户确保对于每个命名空间，它要么具有
Sidecar 注入标签（`istio-injection=enabled`），
要么具有 Ambient 模式标签（`istio.io/dataplane-mode=ambient`），但绝不能两者兼而有之。

## 标签参考 {#ambient-labels}

以下标签控制资源是否被包含在 Ambient 模式下的网格中、
是否使用 waypoint 代理为资源强制执行 L7 策略，以及控制如何将流量发送到 waypoint。

|  名称  | 功能状态 | 资源 | 描述 |
| --- | --- | --- | --- |
| `istio.io/dataplane-mode` | Beta | `Namespace` 或 `Pod`（后者优先） |  将您的资源添加到 Ambient 网格中。<br><br>有效值：`ambient` 或 `none`。 |
| `istio.io/use-waypoint` | Beta | `Namespace`、`Service` 或 `Pod` | 使用流向标记资源的 waypoint 来实施 L7 策略。<br><br>有效值：`{waypoint-name}` 或 `none`。 |
| `istio.io/waypoint-for` | Alpha | `Gateway` | 指定 waypoint 将处理流量的端点类型。<br><br>有效值：`service`、`workload`、`none` 或 `all`。该标签是可选的，默认值为 `service`。 |

为了使您的 `istio.io/use-waypoint` 标签值有效，您必须确保为处理流量的资源类型配置 waypoint。
默认情况下，waypoint 接受服务流量。例如，当您通过 `istio.io/use-waypoint` 标签将
Pod 标记为使用特定 waypoint 时，该 waypoint 应打上 `istio.io./waypoint-for` 标签，取值为 `workload` 或 `all`。

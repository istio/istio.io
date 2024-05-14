---
title: 将工作负载添加到网格中
description: 了解如何将工作负载添加到 Ambient 网格中。
weight: 10
owner: istio/wg-networking-maintainers
test: no
---

In most cases, a cluster administrator will deploy the Istio mesh infrastructure. Once Istio is successfully deployed with support for the ambient {{< gloss >}}data plane{{< /gloss >}} mode, it will be transparently available to applications deployed by all users in namespaces that have been configured to use it.
在大多数情况下，集群管理员将部署 Istio 网格基础设施。
一旦 Istio 成功部署并支持 Ambient {{< gloss "data plane" >}}数据平面{{< /gloss >}}模式，
它将透明地可供所有用户在已配置为使用它的命名空间中部署的应用程序并使用。

## Enabling ambient mode for an application in the mesh
## 为网格中的应用程序启用环境模式 {#enabling-ambient-mode-for-an-application-in-the-mesh}

To add an applications or namespaces to the mesh in ambient mode, add the label `istio.io/dataplane-mode=ambient` to the corresponding resource. You can apply this label to a namespace or to an individual pod.
要在 Ambient 模式下将应用程序或命名空间添加到网格，
请将标签 `istio.io/dataplane-mode=ambient` 添加到相应的资源。
您可以将此标签应用于命名空间或单个 Pod。

Ambient mode can be seamlessly enabled (or disabled) completely transparently as far as the application pods are concerned. Unlike the {{< gloss >}}sidecar{{< /gloss >}} data plane mode, there is no need to restart applications to add them to the mesh, and they will not show as having an extra container deployed in their pod.
就应用程序 Pod 而言，可以完全透明地无缝启用（或禁用）Ambient 模式。
与 {{< gloss "sidecar" >}}Sidecar{{< /gloss >}} 数据平面模式不同，
无需重新启动应用程序即可将它们添加到网格中，并且它们不会显示为在其 Pod 中部署了额外的容器。

### Layer 4 and Layer 7 functionality
### Layer 4 和 Layer 7 功能 {#layer-4-and-layer-7-functionality}

The secure L4 overlay supports authentication and authorization policies. [Learn about L4 policy support in ambient mode](/docs/ambient/usage/l4-policy/). To opt-in to use Istio's L7 functionality, such as traffic routing, you will need to [deploy a waypoint proxy and enroll your workloads to use it](/docs/ambient/usage/waypoint/).
安全的 L4 覆盖支持身份验证和授权策略。
[了解 Ambient 模式下的 L4 策略支持](/zh/docs/ambient/usage/l4-policy/)。
要选择使用 Istio 的 L7 功能（例如流量路由），
您需要[部署一个 waypoint 代理并注册您的工作负载以使用它](/zh/docs/ambient/usage/waypoint/)。

## Communicating between pods in different data plane modes
## 不同数据平面模式下 Pod 之间进行通信 {#communicating-between-pods-in-different-data-plane-modes}

There are multiple options for interoperability between application pods using the ambient data plane mode, and non-ambient endpoints (including Kubernetes application pods, Istio gateways or Kubernetes Gateway API instances). This interoperability provides multiple options for seamlessly integrating ambient and non-ambient workloads within the same Istio mesh, allowing for phased introduction of ambient capability as best suits the needs of your mesh deployment and operation.
使用 Ambient 数据平面模式的应用程序 Pod 与非 Ambient 端点
（包括 Kubernetes 应用程序 Pod、Istio 网关或 Kubernetes Gateway API 实例）
之间的互操作性有多种选择。这种互操作性提供了多种选项，
用于在同一 Istio 网格中无缝集成 Ambient 和非 Ambient 工作负载，
从而允许分阶段引入 Ambient 功能，以最适合网格部署和操作的需求。

### Pods outside the mesh
### 网格外的 Pod {#pods-outside-the-mesh}

You may have namespaces which are not part of the mesh at all, in either sidecar or ambient mode. In this case, the non-mesh pods initiate traffic directly to the destination pods without going through the source node's ztunnel, while the destination pod's ztunnel enforces any L4 policy to control whether traffic should be allowed or denied.
无论是在 Sidecar 还是环境模式下，您的命名空间可能根本不是网格的一部分。 在这种情况下，非网状 Pod 直接向目标 Pod 发起流量，而不经过源节点的 ztunnel，而目标 Pod 的 ztunnel 会强制执行任何 L4 策略来控制是允许还是拒绝流量。

For example, setting a `PeerAuthentication` policy with mTLS mode set to `STRICT`, in a namespace with ambient mode enabled, will cause traffic from outside the mesh to be denied.
例如，在启用了环境模式的命名空间中，将 mTLS 模式设置为“STRICT”的“PeerAuthentication”策略将导致来自网格外部的流量被拒绝。

### Pods inside the mesh using sidecar mode
### 使用 sidecar 模式在网格内放置 Pod

Istio supports East-West interoperability between a pod with a sidecar and a pod using ambient mode, within the same mesh. The sidecar proxy knows to use the HBONE protocol since the destination has been discovered to be an HBONE destination.
Istio 支持同一网格内带有 sidecar 的 pod 和使用环境模式的 pod 之间的东西向互操作性。 由于已发现目标是 HBONE 目标，所以 sidecar 代理知道使用 HBONE 协议。

{{< tip >}}
For sidecar proxies to use the HBONE/mTLS signaling option when communicating with ambient destinations, they need to be configured with `ISTIO_META_ENABLE_HBONE` set to `true` in the proxy metadata. This is the default in `MeshConfig` when using the `ambient` profile, hence you do not have to do anything else when using this profile.
为了使 sidecar 代理在与环境目标通信时使用 HBONE/mTLS 信令选项，需要在代理元数据中将“ISTIO_META_ENABLE_HBONE”设置为“true”进行配置。 这是使用“ambient”配置文件时“MeshConfig”中的默认设置，因此在使用此配置文件时您无需执行任何其他操作。
{{< /tip >}}

A `PeerAuthentication` policy with mTLS mode set to `STRICT` will allow traffic from a pod with an Istio sidecar proxy.
mTLS 模式设置为“STRICT”的“PeerAuthentication”策略将允许来自具有 Istio sidecar 代理的 pod 的流量。

### Ingress and egress gateways and ambient mode pods
### 入口和出口网关以及环境模式 Pod

An ingress gateway may run in a non-ambient namespace, and expose services provided by ambient mode, sidecar mode or non-mesh pods. Interoperability is also supported between pods in ambient mode and Istio egress gateways.
入口网关可以在非环境命名空间中运行，并公开由环境模式、边车模式或非网格 Pod 提供的服务。 环境模式下的 Pod 与 Istio 出口网关之间也支持互操作性。

## Pod selection logic for ambient and sidecar modes
## 环境模式和边车模式的 Pod 选择逻辑

Istio's two data plane modes, sidecar and ambient, can co-exist in the same cluster. It is important to ensure that the same pod or namespace does not get configured to use both modes at the same time. However, if this does occur, the sidecar mode currently takes precedence for such a pod or namespace.
Istio 的两种数据平面模式，sidecar 和ambient，可以在同一个集群中共存。 确保同一 Pod 或命名空间不会配置为同时使用两种模式非常重要。 但是，如果确实发生这种情况，则当前此类 Pod 或命名空间将优先采用 Sidecar 模式。

Note that two pods within the same namespace could in theory be set to use different modes by labeling individual pods separately from the namespace label; however, this is not recommended. For most common use cases a single mode should be used for all pods within a single namespace.
请注意，理论上，通过与命名空间标签分开标记各个 pod，可以将同一命名空间中的两个 pod 设置为使用不同的模式； 但是，不建议这样做。 对于大多数常见用例，单一模式应用于单个命名空间内的所有 Pod。

The exact logic to determine whether a pod is set up to use ambient mode is as follows:
确定 pod 是否设置为使用环境模式的确切逻辑如下：

1. The `istio-cni` plugin configuration exclude list configured in `cni.values.excludeNamespaces` is used to skip namespaces in the exclude list.
1. `cni.values.excludeNamespaces` 中配置的 `istio-cni` 插件配置排除列表用于跳过排除列表中的命名空间。
1. `ambient` mode is used for a pod if
1. pod 使用 `ambient` 模式，如果

    * The namespace or pod has the label `istio.io/dataplane-mode=ambient`
    * 命名空间或 pod 具有标签 `istio.io/dataplane-mode=ambient`
    * The pod does not have the opt-out label `istio.io/dataplane-mode=none`
    * Pod 没有选择退出标签 `istio.io/dataplane-mode=none`
    * The annotation `sidecar.istio.io/status` is not present on the pod
    * Pod 上不存在注释 `sidecar.istio.io/status`

The simplest option to avoid a configuration conflict is for a user to ensure that for each namespace, it either has the label for sidecar injection (`istio-injection=enabled`) or for ambient mode (`istio.io/dataplane-mode=ambient`), but never both.
避免配置冲突的最简单选项是用户确保对于每个命名空间，它要么具有 sidecar 注入标签（`istio-injection=enabled`），要么具有环境模式标签（`istio.io/dataplane-mode= 环境`），但绝不会两者兼而有之。

## Label reference {#ambient-labels}
## 标签参考 {#ambient-labels}

The following labels control if a resource is included in the mesh in ambient mode, if a waypoint proxy is used to enforce L7 policy for your resource, and to control how traffic is sent to the waypoint.
以下标签控制资源是否包含在环境模式下的网格中、是否使用路点代理为资源强制执行 L7 策略，以及控制如何将流量发送到路点。

|  名称  | 功能状态 | 资源 | 描述 |
| --- | --- | --- | --- |
| `istio.io/dataplane-mode` | Beta | `Namespace` 或 `Pod` (latter has precedence) |  Add your resource to an ambient mesh. <br><br> Valid values: `ambient` or `none`. |
| `istio.io/use-waypoint` | Beta | `Namespace`, `Service` or `Pod` | Use a waypoint for traffic to the labeled resource for L7 policy enforcement. <br><br> Valid values: `{waypoint-name}` or `none`. |
| `istio.io/waypoint-for` | Alpha | `Gateway` | Specifies what types of endpoints the waypoint will process traffic for. <br><br> Valid values: `service`, `workload`, `none` or `all`. This label is optional and the default value is `service`. |

In order for your `istio.io/use-waypoint` label value to be effective, you have to ensure the waypoint is configured for the resource types it will be handling traffic for. By default waypoints accept traffic for services. For example, when you label a pod to use a specific waypoint via the `istio.io/use-waypoint` label, the waypoint should be labeled `istio.io./waypoint-for` with the value `workload` or `all`.
为了使您的“istio.io/use-waypoint”标签值有效，您必须确保为将处理流量的资源类型配置路点。 默认情况下，航路点接受服务流量。 例如，当您通过“istio.io/use-waypoint”标签将 pod 标记为使用特定路径点时，该路径点应标记为“istio.io./waypoint-for”，且值为“workload”或“all” `。

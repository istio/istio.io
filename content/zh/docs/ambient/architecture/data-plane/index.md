---
title: Ambient 数据平面
description: 了解 Ambient 数据平面如何在 Ambient 网格中的工作负载之间路由流量。
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

在 {{< gloss "ambient" >}}Ambient 模式{{< /gloss >}}中，工作负载可以分为 3 类：

1. **网格之外**：未启用任何网格功能的标准 Pod。
   Istio 和 Ambient 的{{< gloss "data plane" >}}数据平面{{< /gloss >}}都未被启用。
1. **网格内**：被包含在 Ambient {{< gloss "data plane" >}}数据平面{{< /gloss >}}中的 Pod，
   并通过 {{< gloss >}}ztunnel{{< /gloss >}} 在 4 层级别拦截流量。在此模式下，可以对 Pod 流量实施 L4 策略。
   可以通过设置 `istio.io/dataplane-mode=ambient` 标签来启用此模式。
   有关更多详细信息，请参阅[标签](/zh/docs/ambient/architecture#ambient-labels)。
1. **在网格中，并启用了 waypoint**：**在网格中并且**部署了一个 {{< gloss "waypoint" >}}waypoint 代理{{< /gloss >}}。
   在此模式下，可以对 Pod 流量实施 L7 策略。可以通过设置 `istio.io/use-waypoint` 标签来启用此模式。
   有关更多详细信息，请参阅[标签](/zh/docs/ambient/architecture#ambient-labels)。

根据工作负载所属的类别，流量的路径将有所不同。

## 网格内路由 {#in-mesh-routing}

### 出站 {#outbound}

当 Ambient 网格中的 Pod 发出出站请求时，
它将被[透明地重定向](/zh/docs/ambient/architecture/traffic-redirection)到节点本地 ztunnel，
该 ztunnel 会确定将请求转发到何处以及如何转发。一般来说，流量路由的行为就像 Kubernetes 默认流量路由一样；
对 `Service` 的请求将被发送到 `Service` 内的端点，而直接对 `Pod` IP 的请求将直接发送到其 IP。

然而，根据目的地的权能，可能会出现不同的行为。
如果目的地也被添加到网格中，或以其他方式赋予 Istio 代理权能（例如 Sidecar），
请求将被升级为加密的 {{< gloss "HBONE" >}}HBONE 隧道{{< /gloss >}}。
如果目的地有一个 waypoint 代理，除了升级到 HBONE 之外，该请求还将被转发到该 waypoint 以执行 L7 策略。

请注意，在向 `Service` 发出请求的情况下，如果该服务**具有**一个 waypoint，
则该请求将被发送到其 waypoint 以对流量实施 L7 策略。
类似地，在向 `Pod` IP 发出请求的情况下，如果 Pod **具有**一个 waypoint，
则该请求将被发送到其 waypoint，以对流量实施 L7 策略。由于可以改变 `Deployment` 中与 Pod 关联的标签，
因此从技术上讲，某些 Pod 可以使用 waypoint，而其他 Pod 则不能。通常建议用户避免这种高级用例。

### 入站 {#inbound}

当 Ambient 网格中的 Pod 收到入站请求时，
它将被[透明地重定向](/zh/docs/ambient/architecture/traffic-redirection)到节点本地 ztunnel。
当 ztunnel 收到请求时，它会应用鉴权策略并仅在请求通过这些检查时转发请求。

Pod 可以接收 HBONE 流量或明文流量。这两种流量默认都可以被 ztunnel 接受。
因为源自网格外的请求在评估鉴权策略时没有对等身份，
所以用户可以设置一个策略，要求进行身份验证（可以是**任何**身份验证或特定身份验证），以阻止所有明文流量。

当目标启用 waypoint 时，如果来源位于 Ambient 网格中，
则来源的 ztunnel 确保请求**将**会通过强制执行策略的 waypoint。
但是，网格外部的工作负载对 waypoint 代理一无所知，因此即使目标启用了 waypoint，
它也会直接将请求发送到目标，而不通过任何 waypoint 代理。
目前，来自 Sidecar 和网关的流量也不会通过任何 waypoint 代理，并且它们将在未来版本中感知到 waypoint 代理。

#### 数据平面详细信息 {#dataplane-details}

##### 身份 {#identity}

Ambient 网格中工作负载之间的所有入站和出站 L4 TCP 流量均由数据平面通过
{{< gloss "HBONE" >}}HBONE{{< /gloss >}}、ztunnel 和 x509 证书使用 mTLS 进行保护。

根据 {{< gloss "mutual tls authentication" >}}mTLS{{< /gloss >}} 的强制要求，
源和目标必须具有唯一的 x509 身份，并且必须使用这些身份来为该连接建立加密通道。

这需要 ztunnel 代表代理的工作负载管理多个不同的工作负载证书 - 每个节点本地 Pod 的每个唯一身份（服务帐户）都有一个证书。
ztunnel 自己的身份从不用于工作负载之间的 mTLS 连接。

获取证书时，ztunnel 将使用自己的身份向 CA 进行身份验证，
但会请求另一个工作负载的身份。至关重要的是，CA 必须强制 ztunnel 有权请求该身份。
对未在节点上运行的身份所做的请求将被拒绝。这对于确保受感染的节点不会危及整个网格至关重要。

此 CA 的强制执行由 Istio 的 CA 使用 Kubernetes 服务帐户 JWT 令牌完成，
这种 JWT 令牌会对 Pod 信息进行编码。此强制执行也是与 ztunnel 集成的任何替代 CA 的要求。

ztunnel 将为节点上的所有身份请求证书。
它根据收到的{{< gloss "control plane" >}}控制平面{{< /gloss>}}配置来确定这一点。
当在节点上发现新身份时，它将以低优先级排队等待获取，作为一种优化。
但是，如果请求需要尚未获取的某个身份，则会立即请求该身份。

当这些证书即将到期时，ztunnel 还将处理这些证书的轮换。

##### 可观测 {#telemetry}

ztunnel 发出全套 [Istio 标准 TCP 指标](/zh/docs/reference/config/metrics/)。

##### 4 层流量的数据平面示例 {#dataplane-example-for-layer-4-traffic}

其间的 L4 Ambient 数据平面如下图所示。

{{< image width="100%"
link="ztunnel-datapath-1.png"
caption="基础 ztunnel 仅 L4 数据路径"
>}}

该图显示了添加到 Ambient 网格的多个工作负载，这些工作负载在 Kubernetes 集群的节点 W1 和 W2 上运行。
每个节点上都有一个 ztunnel 代理实例。在此场景中，应用程序客户端 Pod C1、C2 和 C3 需要访问 Pod S1 提供的服务。
不需要 L7 流量路由或 L7 流量管理等高级 L7 功能，因此 L4 数据平面足以获得
{{< gloss "mutual tls authentication" >}}mTLS{{< /gloss >}} 和 L4 策略执行 - 不需要 waypoint 代理。

该图显示在节点 W1 上运行的 Pod C1 和 C2 与在节点 W2 上运行的 Pod S1 连接。

C1 和 C2 的 TCP 流量通过 ztunnel 创建的 {{< gloss >}}HBONE{{< /gloss >}} 连接安全地通过隧道传输。
{{< gloss "mutual tls authentication" >}}双向 TLS（mTLS）{{< /gloss >}}用于加密以及隧道流量的双向身份验证。
[SPIFFE](https://github.com/spiffe/spiffe/blob/main/standards/SPIFFE.md) 身份用于识别连接每一端的工作负载。
有关隧道协议和流量重定向机制的更多详细信息，请参阅 [HBONE](/zh/docs/ambient/architecture/hbone)
和 [ztunnel 流量重定向](/zh/docs/ambient/architecture/traffic-redirection)中的指南。

{{< tip >}}
注意：虽然图中显示 HBONE 隧道位于两个 ztunnel 代理之间，
但是隧道实际上位于源 Pod 和目标 Pod 之间。
流量在源 Pod 本身的网络命名空间中进行 HBONE 封装和加密，
最终在目标工作节点上的目标 Pod 的网络命名空间中解封装和解密。
ztunnel 代理仍然在逻辑上处理 HBONE 传输所需的控制平面和数据平面，
但它能够从源 Pod 和目标 Pod 的网络命名空间内部执行此操作。
{{< /tip >}}

请注意，本地流量（如图所示，从工作节点 W2 上的 Pod C3 到目标 Pod S1）也会遍历本地 ztunnel 代理实例，
因此 L4 授权和 L4 可观测等 L4 流量管理功能将在流量上以相同的方式实施，无论跨越节点边界与否。

## 在启用了 waypoint 的网格路由中 {#in-mesh-routing-with-waypoint-enabled}

Istio waypoint 专门接收 HBONE 流量。
当收到请求后，waypoint 将确保流量适用于使用它的 `Pod` 或 `Service`。

接受流量后，waypoint 将在转发之前强制执行 L7 策略
（例如 `AuthorizationPolicy`、`RequestAuthentication`、`WasmPlugin`、`Telemetry` 等）。

对于直接发送到 `Pod` 的，请求将在应用策略后才会被直接转发。

对于发送到 `Service` 的请求，waypoint 还将应用路由和负载均衡。
默认情况下，`Service` 会简单地将请求路由到本身，在其端点之间进行负载均衡。
这可以重载为针对 `Service` 的路由。

例如，以下策略将确保到 `echo` 服务的请求被转发到 `echo-v1`：

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: echo
  rules:
  - backendRefs:
    - name: echo-v1
      port: 80
{{< /text >}}

下图显示了 ztunnel 和 waypoint 之间的数据路径（如果配置了 L7 策略实施）。
这里 ztunnel 使用 HBONE 隧道将流量发送到 waypoint 代理进行 L7 处理。
处理后，waypoint 通过第二个 HBONE 隧道将流量发送到托管所选服务目标 Pod 的节点上的 ztunnel。
一般来说，waypoint 代理可能位于也可能不位于与源或目标 Pod 相同的节点上。

{{< image width="100%"
link="ztunnel-waypoint-datapath.png"
caption="通过临时 waypoint 的 ztunnel 数据路径"
>}}

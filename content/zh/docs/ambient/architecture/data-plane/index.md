---
title: Ambient 数据平面
description: 了解 Ambient 数据平面如何在 Ambient 网格中的工作负载之间路由流量。
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

在 {{< gloss "ambient" >}}Ambient 模式{{< /gloss >}}中，工作负载分为 3 类：

1. **脱离网格：**这是一个标准 Pod，未启用任何网格功能。
1. **网格内：**这是一个 Pod，其流量被 {{< gloss >}}ztunnel{{< /gloss >}} 在 4 层拦截。
   在此模式下，可以对 Pod 流量实施 L4 策略。可以通过在 Pod 的命名空间上设置 `istio.io/dataplane-mode=ambient` 标签来为 Pod 启用此模式。
   这将为该命名空间中的所有 Pod 启用**网格内**模式。
1. **网格内，启用 waypoint：**这是一个**网格内并且**部署了 {{< gloss "waypoint" >}}waypoint 代理{{< /gloss >}} 的 Pod。
   在此模式下，可以对 Pod 流量实施 L7 策略。
   可以通过设置 `istio.io/use-waypoint` 标签来启用此模式。
   有关更多详细信息，请参阅[标签](/zh/docs/ambient/architecture#ambient-labels)。

根据工作负载所属的类别，请求的路径将有所不同。

## 网格内路由 {#in-mesh-routing}

### 出站 {#outbound}

当处于 Ambient 模式中的 Pod 发出出站请求时，它将被透明地重定向到 Ztunnel，
由 Ztunnel 来决定如何转发请求以及转发到哪儿。总之，流量路由行为就像 Kubernetes 默认的流量路由一样；
到 `Service` 的请求将被发送到 `Service` 内的一个端点，
而直接发送到 `Pod` IP 的请求则将直接转到该 IP。

然而，根据目的地的权能，可能会出现不同的行为。
如果目的地也被添加到网格中，或以其他方式具有 Istio 代理权能（例如 Sidecar），
请求将被升级为加密的 {{< gloss "HBONE" >}}HBONE 隧道{{< /gloss >}}。
如果目的地有一个 waypoint 代理，除了升级到 HBONE 之外，该请求还将被转发到该 waypoint 以执行 L7 策略。

请注意，在向 `Service` 发出请求的情况下，如果该服务**具有**一个 waypoint，
则该请求将被发送到其 waypoint 以对流量实施 L7 策略。
类似地，在向 `Pod` IP 发出请求的情况下，如果 Pod **具有**一个 waypoint，
则该请求将被发送到其 waypoint，以对流量实施 L7 策略。由于可以改变 `Deployment` 中与 Pod 关联的标签，
因此从技术上讲，某些 Pod 可以使用 waypoint，而其他 Pod 则不能。通常建议用户避免这种高级用例。

### 入站 {#inbound}

当处于 Ambient 模式中的 Pod 收到一个入站请求时，它将被透明地重定向到 Ztunnel。
当 Ztunnel 收到请求时，它将应用鉴权策略并仅在请求与策略匹配时转发请求。

Pod 可以接收 HBONE 流量或纯文本流量。这两种流量默认都可以被 Ztunnel 接受。
因为来源自网格外的请求在评估鉴权策略时没有对等身份，
所以用户可以设置一个策略，要求进行身份验证（可以是**任何**身份验证或特定身份验证），以阻止所有纯文本流量。

当目标启用 waypoint 时，如果来源位于 Ambient 网格中，
则来源的 ztunnel 确保请求**必定**会通过强制执行策略的 waypoint。
但是，网格外部的工作负载对 waypoint 代理一无所知，因此即使目标启用了 waypoint，
它也会直接将请求发送到目标，而不通过任何 waypoint 代理。
目前，来自 Sidecar 和网关的流量也不会通过任何 waypoint 代理，并且它们将在未来版本中意识到 waypoint 代理。

#### 数据平面详细信息 {#dataplane-details}

The L4 ambient dataplane between is depicted in the following figure.
其间的 L4 Ambient 数据平面如下图所示。

{{< image width="100%"
link="ztunnel-datapath-1.png"
caption="基础 ztunnel 仅 L4 数据路径"
>}}

该图描绘了 Kubernetes 集群的两个节点 W1 和 W2 上运行的 Ambient Pod 工作负载。
每个节点上都有一个 ztunnel 代理实例。在此场景中，应用程序客户端
Pod C1、C2 和 C3 需要访问由 Pod S1 提供的服务，并且不需要高级 L7 功能
（例如 L7 流量路由或 L7 流量管理），因此不需要 waypoint 代理。

该图显示在节点 W1 上运行的 Pod C1 和 C2 与在节点 W2 上运行的 Pod S1 连接。

C1 和 C2 的 TCP 流量通过 ztunnel 创建的 {{< gloss >}}HBONE{{< /gloss >}}
连接安全地通过隧道传输。{{< gloss "mutual tls authentication" >}}双向 TLS（mTLS）{{< /gloss >}}用于加密以及隧道流量的相互身份验证。
[SPIFFE](https://github.com/spiffe/spiffe/blob/main/standards/SPIFFE.md) 身份用于识别连接每一端的工作负载。
有关隧道协议和流量重定向机制的更多详细信息，请参阅 [HBONE](/zh/docs/ambient/architecture/hbone)
和 [ztunnel 流量重定向](/zh/docs/ambient/architecture/traffic-redirection)中的指南。

{{< tip >}}
注意：虽然图中显示 HBONE 隧道位于两个 ztunnel 代理之间，
隧道实际上位于源 Pod 和目标 Pod 之间。
流量在源 Pod 本身的网络命名空间中进行 HBONE 封装和加密，
最终在目标工作节点上的目标 Pod 的网络命名空间中解封装和解密。
ztunnel 代理仍然在逻辑上处理 HBONE 传输所需的控制平面和数据平面，
但它能够从源 Pod 和目标 Pod 的网络命名空间内部执行此操作。
{{< /tip >}}

请注意，该图展示本地流量（从 Pod C3 到工作节点 W2 上的目标 Pod S1）
无论是否跨越节点边界也会遍历本地 ztunnel 代理实例，
以便对流量执行相同的 L4 流量管理功能（例如 L4 鉴权和 L4 遥测）。

## 启用了 waypoint 的网格内 {#in-mesh-routing-with-waypoint-enabled}

waypoint 专门接收 HBONE 请求。收到请求后，
waypoint 将确保流量适用于使用它的 `Pod` 或 `Service`。

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

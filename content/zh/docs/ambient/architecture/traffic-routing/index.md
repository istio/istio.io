---
title: 流量路由
description: 了解流量如何在 Ambient 网格中的工作负载之间路由。
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

在 {{< gloss "ambient" >}}Ambient 模式{{< /gloss >}}中，工作负载分为 3 类：
1. **脱离网格：**这是一个标准 Pod，未启用任何网格功能。
1. **网格内：**这是一个 Pod，其流量被 {{< gloss >}}ztunnel{{< /gloss >}} 在 4 层拦截。
   在此模式下，可以对 Pod 流量实施 L4 策略。可以通过在 Pod 的命名空间上设置 `istio.io/dataplane-mode=ambient` 标签来为 Pod 启用此模式。
   这将为该命名空间中的所有 Pod 启用**网格内**模式。
1. **启用 waypoint：**这是一个“网格内”的 Pod，**并且**部署了 {{< gloss "waypoint" >}}waypoint 代理{{< /gloss >}}。

根据工作负载所属的类别，请求路径会有所不同。

## Ztunnel 路由 {#ztunnel-routing}

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

## Waypoint 路由 {#waypoint-routing}

waypoint 以独占方式接收 HBONE 请求。
收到请求后，waypoint 将确保流量适用于使用它的 `Pod` 或 `Service`。

接受流量后，waypoint 将在转发之前强制执行 L7 策略
（例如 `AuthorizationPolicy`、`RequestAuthentication`、`WasmPlugin`、`Telemetry` 等）。

对与直接发送到 `Pod` 的，请求将在应用策略后才会被直接转发。

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

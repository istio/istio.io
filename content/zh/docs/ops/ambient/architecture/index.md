---
title: Ambient Mesh 架构
description: 深入了解 Ambient Mesh 架构。
weight: 3
owner: istio/wg-networking-maintainers
test: n/a
---

本页还在进一步建设中。

## 与 Sidecar 架构的不同之处 {#differences-from-sidecar}

## 流量路由 {#traffic-routing}

在 {{< gloss "ambient" >}}Ambient 模式{{< /gloss >}}中，工作负载分为 3 类：

1. **Uncaptured:** 这是一个未启用任何网格特性的标准 Pod。
1. **Captured:** 这是流量已被 {{< gloss >}}Ztunnel{{< /gloss >}} 截取的 Pod。
    通过在命名空间上设置 `istio.io/dataplane-mode=ambient` 标签可以捕获 Pod。
1. **Waypoint enabled:** 这是 一个被"捕获" **且** 部署了
    {{< gloss "waypoint" >}}waypoint 代理{{< /gloss >}}的 Pod。
    waypoint 默认将应用到同一命名空间中的所有 Pod。
    通过在 `Gateway` 上使用 `istio.io/for-service-account` 注解，
    可以选择将 waypoint 仅应用到特定的服务账号。
    如果同时存在命名空间 waypoint 和服务账号 waypoint，将优先使用服务账号 waypoint。

根据工作负载所属的类别，请求的路径将有所不同。

### Ztunnel 路由 {#ztunnel-routing}

#### 出站 {#outbound}

当被捕获的 Pod 发出出站请求时，它将被透明地重定向到 Ztunnel，由Ztunnel 来决定如何转发请求以及转发到哪儿。
总之，流量路由行为就像 Kubernetes 默认的流量路由一样；
到 `Service` 的请求将被发送到 `Service` 内的一个端点，
而直接发送到 `Pod` IP 的请求则将直接转到该 IP。

然而，根据目的地的权能，可能会出现不同的行为。
如果目的地也被捕获，或以其他方式具有 Istio 代理权能（例如 Sidecar），
请求将被升级为加密的 {{< gloss "HBONE" >}}HBONE 隧道{{< /gloss >}}。
如果目的地有一个 waypoint 代理，除了升级到 HBONE 之外，请求将被转发到该 waypoint。

请注意，对于到 `Service` 的请求，将选择特定的端点来决定其是否具有 waypoint。
然而，如果请求 **具有** waypoint，请求将随着 `Service` 的目标目的地而不是所选的端点被发送。
这就允许 waypoint 将面向服务的策略应用到流量。
在极少情况下，`Service` 会混合使用启用/未启用 waypoint 的端点，
某些请求将被发送到 waypoint，而到相同服务的其他请求不会被发送到 waypoint。

#### 入站{#inbound}

当被捕获的 Pod 收到一个入站请求时，它将被透明地重定向到 Ztunnel。
当 Ztunnel 收到请求时，它将应用鉴权策略并仅在请求与策略匹配时转发请求。

Pod 可以接收 HBONE 流量或纯文本流量。
这两种流量默认都可以被 Ztunnel 接受。
因为纯文本请求在评估鉴权策略时没有对等身份，
所以用户可以设置一个策略，要求进行身份验证（可以是 **任何** 身份验证或特定身份验证），以阻止所有纯文本流量。

当目的地启用 waypoint 时，所有请求 **必须** 通过 waypoint 来执行策略。
Ztunnel 将确保达成这种行为。
然而，存在一些边缘场景：一个行为良好的 HBONE 客户端（例如另一个 Ztunnel 或 Istio Sidecar）
知道发送到 waypoint，但其他客户端（例如网格外的工作负载）可能不知道 waypoint 代理的任何信息并直接发送请求。
当进行这些直接调用时，Ztunnel 将使请求"红头文件"调整到其自身 waypoint 的请求，以确保这些策略被正确执行。

### Waypoint 路由{#waypoint-routing}

waypoint 以独占方式接收 HBONE 请求。
在收到一个请求时，waypoint 将确保此请求指向其管理的 `Pod` 或包含所管理 `Pod` 的 `Service`。

对于任何请求类型，waypoint 将在转发请求之前执行策略
（例如 `AuthorizationPolicy`、`WasmPlugin`、`Telemetry` 等）。

对与直接发送到 `Pod` 的，请求将在应用策略后才会被直接转发。

对于发送到 `Service` 的请求，waypoint 还将应用路由和负载均衡。
默认情况下，`Service` 会简单地将请求路由到本身，在其端点之间进行负载均衡。
这可以重载为针对 `Service` 的路由。

例如，以下策略将确保到 `echo` 服务的请求被转发到 `echo-v1`：

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: echo
spec:
  parentRefs:
  - kind: Service
    name: echo
  rules:
  - backendRefs:
    - name: echo-v1
      port: 80
{{< /text >}}

## 安全 {#security}

本节内容正在制作中。

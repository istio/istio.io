---
title: 了解流量路由
linktitle: Traffic Routing
description: Istio 如何通过网格来路由流量。
weight: 30
keywords: [traffic-management,proxy]
owner: istio/wg-networking-maintainers
test: n/a
---

Istio 的目标之一是充当可以投入到现有集群中的“透明代理”，允许流量像以前一样流动。
然而，由于请求负载均衡等额外特性，Istio 不同于传统的 Kubernetes 集群，可以采用更强大的方式管理流量。
要了解网格中发生了什么，重要的是了解 Istio 如何路由流量。

{{< warning >}}
本文描述了低级别的实现细节。要获取更高级别的概述，
请查阅流量管理[概念](/zh/docs/concepts/traffic-management/)或[任务](/zh/docs/tasks/traffic-management/)。
{{< /warning >}}

## 前端和后端 {#frontends-and-backends}

在 Istio 的流量路由中，有两个主要阶段：

- "前端"是指我们匹配正在处理的流量类型的方式。
  这是为了确定将流量路由到哪个后端以及应用哪些策略而必要的。
  例如，我们可以读取 `http.ns.svc.cluster.local` 的 `Host` 头，
  并确定请求是针对 `http` 服务的。
  有关此匹配工作原理的更多信息可以在下面找到。

- "后端"是指我们在匹配流量后将其发送到的位置。
  使用上面的示例，当确定请求针对 `http` 服务时，我们会将其发送到该服务中的一个端点。
  但是，这个选择并不总是那么简单；Istio 允许通过 `VirtualService` 路由规则自定义此逻辑。

标准的 Kubernetes 网络也具有相同的概念，但它们要简单得多，通常是隐藏的。
当创建一个 `Service` 时，通常会有一个关联的前端 - 自动被创建的 DNS 名称
（例如 `http.ns.svc.cluster.local`），以及表示该服务的自动被创建的 IP 地址（`ClusterIP`）。
类似地，还会创建一个后端（`Endpoints` 或 `EndpointSlice`），它表示由服务选择的所有 Pod。

## 协议 {#protocols}

与 Kubernetes 不同，Istio 可以处理 HTTP 和 TLS 这类应用程序级协议。
相比 Kubernetes 中可用的类型，这样可以匹配不同类型的[前端](#frontends-and-backends)。

一般来说，Istio 能够理解三类协议：

- HTTP，包括 HTTP/1.1、HTTP/2 和 gRPC。请注意，这不包括 TLS 加密流量（HTTPS）。
- TLS，包括 HTTPS。
- 原始 TCP 字节。

[协议选择](/zh/docs/ops/configuration/traffic-management/protocol-selection/)文档描述了
Istio 如何决定使用哪种协议。

在其他情况下，“TCP” 的使用可能会令人困惑，因为在其他上下文中 TCP 用于区分 UDP 等其他 L4 协议。
当涉及到 Istio 中的 TCP 协议时，这通常意味着我们将其视为原始的字节流，
并且不解析 TLS 或 HTTP 这类应用程序级协议。

## 流量路由 {#traffic-routing}

当 Envoy 代理收到请求时，必须决定将此请求转发到哪里。
默认将转发到被请求的原始服务，除非进行了[自定义](/zh/docs/tasks/traffic-management/traffic-shifting/)。
处理方式取决于使用的协议。

### TCP

处理 TCP 流量时，Istio 可用于路由连接的有用信息非常少（只有目标 IP 和端口）。
这些属性用于决定预期的服务；代理被配置为在每个服务 IP（`<Kubernetes ClusterIP>:<Port>`）
对上侦听并将流量转发到上游服务。

对于自定义，可以配置 TCP `VirtualService`，
允许[匹配特定的 IP 和端口](/zh/docs/reference/config/networking/virtual-service/#L4MatchAttributes)
并将其路由到与请求不同的上游服务。

### TLS

处理 TLS 流量时，Istio 提供了比原始 TCP 更多的可用信息：
我们可以检查 TLS 握手期间呈现的
[SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) 字段。

对于标准服务，与原始 TCP 一样使用相同的 IP:Port 匹配机制。
然而对于未定义 Service IP 的服务（例如 [ExternalName 服务](#externalname-services)），
将使用 SNI 用于路由。

此外，可以使用 TLS `VirtualService` 配置自定义路由，
以[匹配 SNI](/zh/docs/reference/config/networking/virtual-service/#TLSMatchAttributes)
并将请求路由到自定义目的地。

### HTTP

HTTP 允许比 TCP 和 TLS 更丰富的路由。使用 HTTP，您可以路由单个 HTTP 请求，而不仅仅是连接。
此外，还可以使用许多丰富的属性，例如主机、路径、标头、查询参数等。

虽然 TCP 和 TLS 流量不管有或没有 Istio 时表现的行为都相同（假设未应用任何配置来自定义路由），
但是 HTTP 存在显著差异。

- Istio 将对个别请求执行负载均衡。通常，这是非常理想的，特别是在具有长期连接的情况下，
  例如 gRPC 和 HTTP/2，在这些情况下，连接级负载均衡是无效的。

- 请求基于端口和 **`Host` 头信息**而不是端口和 IP 被路由。
  这意味着目标 IP 地址实际上被忽略。
  例如 `curl 8.8.8.8 -H "Host: productpage.default.svc.cluster.local"`
  将被路由到 `productpage` 服务。

## 未匹配的流量 {#unmatched-traffic}

如果不能使用上述任何一种方法匹配流量，
则将其视为[透传](/zh/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services)。
默认情况下，这些请求将按原样转发，确保对 Istio 未感知的服务
（例如没有创建 `ServiceEntry` 的外部服务）的流量继续起作用。
请注意，当转发这些请求时，将不使用双向 TLS，并且遥测收集也会受限。

## 服务类型 {#service-types}

除了标准的 `ClusterIP` 服务之外，Istio 还支持完整范围的 Kubernetes 服务，附带一些注意事项。

### `LoadBalancer` 和 `NodePort` 服务 {#loadbalancer-and-nodeport-services}

这些服务是 `ClusterIP` 服务的超集，并且主要与允许来自外部客户端的访问有关。
Istio 支持这些服务类型，并且与标准的 `ClusterIP` 服务具有完全相同的行为。

### 无头服务 {#headless-services}

[无头服务](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#headless-services)是没有分配
`ClusterIP` 的服务。相反，DNS 响应将包含属于服务的每个端点（即 Pod IP）的 IP 地址。

总体而言，Istio 不会为每个 Pod IP 配置侦听器，因为它作用于服务级别。
但是，为了支持无头服务，在无头服务中的每个 IP:Port 对上设置侦听器。
一个例外是对于声明为 HTTP 的协议，它将通过 `Host` 头来匹配流量。

{{< warning >}}
在没有 Istio 的情况下，无头服务的 `ports` 字段不是严格必需的，
因为请求直接发送到 Pod IP，该 IP 可以在所有端口上接受流量。
但是，在使用 Istio 时，必须在服务中声明端口，否则将[不会被匹配](#unmatched-traffic)。
{{< /warning >}}

### ExternalName 服务 {#externalname-services}

[ExternalName 服务](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#externalname)本质上只是
DNS 别名。

为了更具体地说明，考虑以下示例：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: alias
spec:
  type: ExternalName
  externalName: concrete.example.com
{{< /text >}}

因为没有 `ClusterIP` 和 Pod IP 可供匹配，所以对于 TCP 流量，在 Istio 中流量匹配没有任何变化。
当 Istio 接收到请求时，它们将看到 `concrete.example.com` 的 IP。
如果这是 Istio 已知的一个服务，它将按照上述描述进行路由。
如果不是，则将处理为[未匹配流量](#unmatched-traffic)。

对于基于主机名进行匹配的 HTTP 和 TLS，情况有所不同。
如果目标服务（`concrete.example.com`）是 Istio 已知的服务，
则主机别名（`alias.default.svc.cluster.local`）将被添加为 [TLS](#tls)
或 [HTTP](#http) 匹配的**额外**匹配项。
如果不是，则不会有任何变化，因此将处理为[未匹配流量](#unmatched-traffic)。

`ExternalName` 服务本身永远不能成为[后端](#frontends-and-backends)。
相反，它只能作为现有服务的附加[前端](#frontends-and-backends)匹配项使用。
如果明确将其用作后端，例如在 `VirtualService` 的目标中，同样的别名适用。
也就是说，如果将 `alias.default.svc.cluster.local` 设置为目标，
那么请求将发送到 `concrete.example.com`。如果 Istio 不知道该主机名，
则请求将失败；在这种情况下，为 `concrete.example.com` 创建一个
`ServiceEntry` 可以使此配置生效。

### ServiceEntry

除了 Kubernetes 服务之外，可以创建[服务条目](/zh/docs/reference/config/networking/service-entry/#ServiceEntry)来扩展
Istio 已知的服务集。这可用于确保到外部服务（例如 example.com）的流量能够加持 Istio 的各项功能。

设置了 `addresses` 的 ServiceEntry 将执行与 `ClusterIP` 服务完全相同的路由。

但是，对于没有任何 `addresses` 的服务条目，将匹配端口上的所有 IP。
这可能会防止在同一端口上的[不匹配流量](#unmatched-traffic)被正确转发。
因此，在可能的情况下最好避免使用它们，或者在需要时使用专用端口。
HTTP 和 TLS 不共享此约束条件，因为基于 hostname/SNI 进行路由。

{{< tip >}}
`addresses` 字段和 `endpoints` 字段经常被混淆。
`addresses` 是指将与之匹配的 IP，而 `endpoints` 是将发送流量的目标 IP 集合。

例如，下面的服务条目将匹配 `1.1.1.1` 的流量，并按照配置的负载均衡策略将请求发送到 `2.2.2.2` 和 `3.3.3.3`：

{{< text yaml >}}
addresses: [1.1.1.1]
resolution: STATIC
endpoints:
- address: 2.2.2.2
- address: 3.3.3.3
{{< /text  >}}

{{< /tip >}}

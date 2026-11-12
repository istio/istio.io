---
title: IngressRouteRulesNotAffected
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当绑定到网关的 `VirtualService` 将流量发送到某个主机时未指定子集，
而另一个 `VirtualService` 使用子集将流量路由到同一主机时，会出现此消息。

网关只使用绑定到它的 `VirtualService` 资源。因此，
另一个 `VirtualService` 中的子集规则对通过网关进入的请求不起作用。

## 示例 {#example}

假设有以下两个 `VirtualService` 资源：

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews-ingress
spec:
  hosts:
  - "reviews.example.com"
  gateways:
  - reviews-gateway
  http:
  - route:
    - destination:
        host: reviews
{{< /text >}}

通过 `reviews-gateway` 进入的请求会被发送到 `reviews` 的所有版本，而不仅仅是 `v1`。
您将收到以下消息：

{{< text plain >}}
Warning [IST0140] (VirtualService default/reviews-ingress) Subset in virtual service default/reviews has no effect on ingress gateway default/reviews-ingress requests
{{< /text >}}

## 如何修复 {#how-to-resolve}

执行以下操作之一：

- 在绑定到网关的 `VirtualService` 的路由中添加子集。
- 将网关添加到包含子集规则的 `VirtualService` 的 `gateways` 字段中。

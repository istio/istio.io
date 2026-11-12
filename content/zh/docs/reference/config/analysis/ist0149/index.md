---
title: JwtClaimBasedRoutingWithoutRequestAuthN
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当绑定到网关的 `VirtualService` 基于 JWT 声明路由流量，
但没有任何 `RequestAuthentication` 应用于网关 Pod 时，会出现此消息。

网关必须先验证 JWT，声明才能用于路由。如果没有 `RequestAuthentication`，
基于 `@request.auth.claims` 进行匹配的路由将无法生效。

## 示例 {#example}

假设没有任何 `RequestAuthentication` 选择网关 Pod，并有如下 `VirtualService`：

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /headers
      headers:
        "@request.auth.claims.groups":
          exact: group1
    route:
    - destination:
        host: httpbin
{{< /text >}}

您将收到如下消息：

{{< text plain >}}
Error [IST0149] (VirtualService default/httpbin) The virtual service uses the JWT claim based routing (key: groups) but found no request authentication for the gateway (default/httpbin-gateway) pod (istio-ingressgateway-5bdb6f9c8b-xk2vz). The request authentication must first be applied for the gateway pods to validate the JWT token and make the claims available for routing.
{{< /text >}}

## 如何修复 {#how-to-resolve}

在网关 Pod 所在的命名空间或根命名空间中，应用一个选择网关 Pod 的 `RequestAuthentication`。
示例请参阅[基于 JWT 声明的路由](/zh/docs/tasks/security/authentication/jwt-route/)。

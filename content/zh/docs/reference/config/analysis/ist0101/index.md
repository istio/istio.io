---
title: ReferencedResourceNotFound
layout: analysis-message
---

当一个 Istio 资源引用另一个不存在的资源时，会触发此消息。当 Istio 试图查找引用的资源，但是找不到它时，这将导致错误。

例如，你收到这个错误:

{{< text plain >}}
Error [IST0101] (VirtualService httpbin.default) Referenced gateway not found: "httpbin-gateway-bogus"
{{< /text >}}

在这个例子中, `VirtualService` 指向一个不存在的网关:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http2
      protocol: HTTP2
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway-bogus #  Should have been "httpbin-gateway"
  http:
  - route:
    - destination:
        host: httpbin-gateway
{{< /text >}}

要解决此问题，请在详细的错误消息中找到资源类型，修正 Istio 配置并重试。

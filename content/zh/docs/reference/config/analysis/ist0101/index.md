---
title: ReferencedResourceNotFound
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当 Istio 资源引用另一个不存在的资源时，会出现此消息。
这会导致 Istio 尝试查找引用的资源但找不到这类的错误。

例如，您会收到这个错误提示：

{{< text plain >}}
Error [IST0101] (VirtualService httpbin.default) Referenced gateway not found: "httpbin-gateway-bogus"
{{< /text >}}

在以下例子中，`VirtualService` 指向了一个不存在的网关：

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
  - httpbin-gateway-bogus # 应该是 "httpbin-gateway"
  http:
  - route:
    - destination:
        host: httpbin-gateway
{{< /text >}}

要解决此问题，请在详细的错误消息中找到资源类型，修正 Istio 配置并重试。

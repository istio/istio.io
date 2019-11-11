---
title: ReferencedResourceNotFound
layout: analysis-message
---

This message occurs when an Istio resource references another resource that does
not exist. This will lead to errors when Istio tries to look up the referenced
resource but cannot find it.

For example, you receive this error:

{{< text plain >}}
Error [IST0101] (VirtualService httpbin.default) Referenced gateway not found: "httpbin-gateway-bogus"
{{< /text >}}

In this example, the `VirtualService` refers to a gateway that does not exist:

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

To resolve this problem, look for the resource type in the detailed error
message, correct your Istio configuration and try again.

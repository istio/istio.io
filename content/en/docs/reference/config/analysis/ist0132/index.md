---
title: VirtualServiceHostNotFoundInGateway
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

This message occurs when a `host` defined in a virtual service is not found in the corresponding gateway.

## Example

You will receive this message:

{{< text plain >}}
Warning [IST0132] (VirtualService testing-service.default testing.yaml:8) one or more host [wrong.com] defined in VirtualService default/testing-service not found in Gateway istio-system/testing-gateway.
{{< /text >}}

when your cluster has the following virtual service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: testing-service
  namespace: default
spec:
  gateways:
  - istio-system/testing-gateway
  hosts:
  - wrong.com
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: ratings
{{< /text >}}

and the following Gateway:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: testing-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - testing.com
    port:
      name: http
      number: 80
      protocol: HTTP
{{< /text >}}

In this example, virtual service `testing-service` has host `wrong.com` which is not included in the gateway `testing-gateway`.

## How to resolve

Make sure all `hosts` in a virtual service are included in the `hosts` of gateways that are bound to the virtual service.

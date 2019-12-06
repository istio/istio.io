---
title: GatewayPortNotOnWorkload
layout: analysis-message
---

This message occurs when a gateway (usually `istio-ingressgateway`) offers a
port that the Kubernetes service workload selected by the gateway does not.

For example, your Istio configuration contains these values:

{{< text yaml >}}
# Gateway with bogus port

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
      name: http
      protocol: HTTP
    hosts:
    - "*"
  - port:
      number: 8004
      name: http2
      protocol: HTTP
    hosts:
    - "*"
{{< /text >}}

In this example, the `GatewayPortNotOnWorkload` message occurs because this
configuration uses port 8004, but a default `IngressGateway` is only open on ports
80, 443, 31400, and 15443.

To resolve this problem, change your gateway configuration to use a valid port
on the workload and try again.

---
title: GatewayDuplicateCertificate
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when two or more `Gateway` resources that select the same gateway workload use the
same TLS certificate.

Clients such as browsers can use one HTTP/2 connection for all hosts that a certificate covers.
If the hosts are in different `Gateway` resources, the gateway can receive a request for a host on
a connection that was opened for a different `Gateway`. The gateway then returns a `404` response.

The analyzer finds the same certificate when the servers use the same `credentialName`, or the
same `serverCertificate` and `privateKey`.

## An example

Consider two `Gateway` resources that select the same workload and use the same `credentialName`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: gateway-a
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - a.example.com
    tls:
      mode: SIMPLE
      credentialName: example-com-cert
---
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: gateway-b
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - b.example.com
    tls:
      mode: SIMPLE
      credentialName: example-com-cert
{{< /text >}}

You will receive this message:

{{< text plain >}}
Warning [IST0138] (Gateway default/gateway-a) Duplicate certificate in multiple gateways [default/gateway-a default/gateway-b] may cause 404s if clients re-use HTTP2 connections.
{{< /text >}}

## How to resolve

Do one of these:

- Put all hosts that share the certificate in one server of one `Gateway`.
- Use a different certificate for each `Gateway`.

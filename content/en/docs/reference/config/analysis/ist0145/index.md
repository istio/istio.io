---
title: ConflictingGateways
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when two or more `Gateway` resources select the same gateway workload, use the
same port, and have hosts that are the same or that overlap. Only one of these servers can be used.

## An example

Consider these two `Gateway` resources:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: alpha
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "foo.example.com"
---
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: beta
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*.example.com"
{{< /text >}}

You will receive this message:

{{< text plain >}}
Error [IST0145] (Gateway default/alpha) Conflict with gateways default/beta (workload selector istio=ingressgateway, port 80, hosts foo.example.com).
{{< /text >}}

## How to resolve

Do one of these:

- Put the hosts in one `Gateway` resource.
- Make sure that the hosts do not overlap.
- Use a different port or a different gateway workload for one of the `Gateway` resources.

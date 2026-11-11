---
title: IngressRouteRulesNotAffected
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a `VirtualService` that is bound to a gateway sends traffic to a host without
a subset, and a different `VirtualService` uses subsets to route traffic to the same host.

A gateway only uses the `VirtualService` resources that are bound to it. Thus, the subset rules in the
other `VirtualService` have no effect on requests that come through the gateway.

## An example

Consider these two `VirtualService` resources:

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

Requests that come through `reviews-gateway` go to all versions of `reviews`, not only to `v1`.
You will receive this message:

{{< text plain >}}
Warning [IST0140] (VirtualService default/reviews-ingress) Subset in virtual service default/reviews has no effect on ingress gateway default/reviews-ingress requests
{{< /text >}}

## How to resolve

Do one of these:

- Add the subset to the route in the `VirtualService` that is bound to the gateway.
- Add the gateway to the `gateways` field of the `VirtualService` that has the subset rules.

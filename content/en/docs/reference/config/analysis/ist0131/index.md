---
title: VirtualServiceIneffectiveMatch
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

This message occurs when a virtual service contains a match rule that will never be used because a previous rule specifies the same match.

## Example

You will receive this message:

{{< text plain >}}
Info [IST0131] (VirtualService tls-routing.default) VirtualService rule #1 match #0 is not used (duplicates a match in rule #0).
{{< /text >}}

when your cluster has the following virtual service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: tls-routing
spec:
  hosts:
  - www1.googleapis.com
  - api1.facebook.com
  tls:
  - match:
    - port: 2443
      sniHosts:
      - www1.googleapis.com
    route:
    - destination:
        host: www1.googleapis.com
  - match:
    - port: 2443
      sniHosts:
      - www1.googleapis.com
    route:
    - destination:
        host: api1.facebook.com
{{< /text >}}

In this example, the virtual service specifies two different destinations
for the same match.  Istio will use the first match, and never send traffic to
the second destination.

## How to resolve

If you need traffic to go to more than one place, use `mirror`.

Re-order your routes so that the most specific ones are first.  Place 'catch all'
routes at the end.

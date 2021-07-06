---
title: VirtualServiceUnreachableRule
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

This message occurs when a virtual service contains a match rule that will never be used because a previous rule specifies the same match.  It also occurs when there is more
than one rule without any match at all.

## Example

You will receive this message:

{{< text plain >}}
Warning [IST0130] (VirtualService sample-foo-cluster01.default) VirtualService rule #1 not used (only the last rule can have no matches).
{{< /text >}}

when your cluster has the following virtual service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: sample-foo-cluster01
  namespace: foo
spec:
  hosts:
  - sample.foo.svc.cluster.local
  http:
  - fault:
      delay:
        fixedDelay: 5s
        percentage:
          value: 100
    route:
    - destination:
        host: sample.foo.svc.cluster.local
  - mirror:
      host: sample.bar.svc.cluster.local
    route:
    - destination:
        host: sample.bar.svc.cluster.local
        subset: v1
{{< /text >}}

In this example, the virtual service specifies
both a fault and a mirror. Having both is allowed, but they must be in
the same route entry. Here the user
has used two different http route entries (one for each `-`), the first
overrides the second.

## How to resolve

When you have an `http` with no `match`, there can only be one http route.
In this case, removing the `"-"` before `mirror` indicates there is a single matchless route that both injects a fault and mirrors, not one route that faults and one that mirrors.

Be careful with YAML formatting when setting up complex routing.

Re-order your routes so that the most specific ones are first.  Place 'catch all'
routes at the end.

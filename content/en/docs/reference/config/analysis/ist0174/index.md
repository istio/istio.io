---
title: UnknownDestinationRuleHost
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when the `host` of a `DestinationRule` does not match a service in the mesh.
The service can be a Kubernetes `Service` or a host in a `ServiceEntry`.

## An example

Consider this `DestinationRule`, when there is no `reveiws` service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reveiws
{{< /text >}}

You will receive this message:

{{< text plain >}}
Warning [IST0174] (DestinationRule default/reviews) The host reveiws defined in the DestinationRule does not match any services in the mesh.
{{< /text >}}

## How to resolve

- Make sure that the host is spelled correctly.
- If the service is in a different namespace, use the fully qualified name of the host, for
  example `reviews.bookinfo.svc.cluster.local`.
- Make sure that the `exportTo` field of the service makes it visible to the namespace of the
  `DestinationRule`.
- If the host is outside the mesh, create a `ServiceEntry` for it.

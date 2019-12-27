---
title: ConflictingMeshGatewayVirtualServiceHosts
layout: analysis-message
---

This message occurs when Istio detects an overlap between
[virtual service](/docs/reference/config/networking/virtual-service)
resources that conflict with one another. For example, multiple virtual
services defined to use the same hostname and attached to a mesh gateway
will generate an error message. Note that Istio supports merging of virtual
services that are attached to the ingress gateways.

## Resolution

To resolve this issue, you can take one of the following actions:

* Merge the conflicting virtual services into a single resource.
* Make the hostnames unique across virtual services attached to a mesh gateway.
* Scope the resource to a specific namespace by setting the `exportTo` field.

## Examples

The `productpage` virtual service in namespace `team1` conflicts with the
`custom` virtual service in `team2` namespace because both of the following
are true:

* They are attached to the default "mesh" gateway as no custom gateway is
specified.
* They both define the same host `productpage.default.svc.cluster.local`.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage
  namespace: team-1
spec:
  hosts:
  - productpage.default.svc.cluster.local
  http:
  - route:
    - destination:
        host: productpage
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: custom
  namespace: team-2
spec:
  hosts:
  - productpage.default.svc.cluster.local
  http:
  - route:
    - destination:
        host: productpage.team-2.svc.cluster.local
---
{{< /text >}}

You can resolve this issue by setting the `exportTo` field to `.` so
that each virtual service is scoped only to its own namespace:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage
  namespace: team-1
spec:
  exportTo:
  - "."
  hosts:
  - productpage.default.svc.cluster.local
  http:
  - route:
    - destination:
        host: productpage
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: custom
  namespace: team-2
spec:
  exportTo:
  - "."
  hosts:
  - productpage.default.svc.cluster.local
  http:
  - route:
    - destination:
        host: productpage.team-2.svc.cluster.local
---
{{< /text >}}

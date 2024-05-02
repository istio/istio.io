---
title: Traffic routing
description: Understand how traffic is routed between workloads in an ambient mesh.
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

In {{< gloss "ambient" >}}ambient mode{{< /gloss >}}, workloads can fall into 3 categories:
1. **Out of Mesh**: a standard pod without any mesh features enabled.
1. **In Mesh**: a pod that has traffic intercepted at the Layer 4 level by {{< gloss >}}ztunnel{{< /gloss >}}. In this mode, L4 policies can be enforced for pod traffic. This mode can be enabled for a pod by setting the `istio.io/dataplane-mode=ambient` label on the pod's namespace. This will enable *in mesh* mode for all pods in that namespace.
1. **Waypoint enabled**: a pod that is "in mesh" *and* has a {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} deployed.

Depending on which category a workload is in, the request path will be different.

## Ztunnel routing

### Outbound

When a pod in an ambient mesh makes an outbound request, it will be transparently redirected to ztunnel which will determine where and how to forward the request.
In general, the traffic routing behaves just like Kubernetes default traffic routing;
requests to a `Service` will be sent to an endpoint within the `Service` while requests directly to a `Pod` IP will go directly to that IP.

However, depending on the destination's capabilities, different behavior will occur.
If the destination is also added in the mesh, or otherwise has Istio proxy capabilities (such as a sidecar), the request will be upgraded to an encrypted {{< gloss "HBONE" >}}HBONE tunnel{{< /gloss >}}.
If the destination has a waypoint proxy, in addition to being upgraded to HBONE, the request will also be forwarded to that waypoint for L7 policy enforcement.

Note that in the case of a request to a `Service`, if the service *has* a waypoint, the request will be sent to its waypoint to enforce L7 policies to the traffic.
Similarly, in the case of a request to a `Pod` IP, if the pod *has* a waypoint, the request will be sent to its waypoint to enforce L7 policies to the traffic.
Since it is possible to vary the labels associated with pods in a `Deployment` it is technically possible for
some pods to use a waypoint while others do not. Users are generally recommended to avoid this advanced use-case.

### Inbound

When a pod in an ambient mesh receives an inbound request, it will be transparently redirected to ztunnel.
When ztunnel receives the request, it will apply Authorization Policies and forward the request only if the request meets the policies.

A pod can receive HBONE traffic or plaintext traffic.
By default, both will be accepted by ztunnel.
Because requests from sources out of mesh will have no peer identity when Authorization Policies are evaluated,
a user can set a policy requiring an identity (either *any* identity, or a specific one) to block all plaintext traffic.

When the destination is waypoint enabled, if the source is in ambient mesh, the source's ztunnel ensures the request **must** go through
the waypoint where policy is enforced. However, a workload outside of the mesh doesn't know anything about waypoint proxies therefore it sends
requests directly to the destination without going through any waypoint proxy even if the destination is waypoint enabled.
Currently, traffic from sidecars and gateways won't go through any waypoint proxy either and they will be made aware of waypoint proxies
in a future release.

## Waypoint routing

A waypoint exclusively receives HBONE requests.
Upon receiving a request, the waypoint will ensure that the traffic is for a `Pod` or `Service` which uses it.

Having accepted the traffic, the waypoint will then enforce L7 policies (such as `AuthorizationPolicy`, `RequestAuthentication`, `WasmPlugin`, `Telemetry`, etc) before forwarding.

For direct requests to a `Pod`, the requests are simply forwarded directly after policy is applied.

For requests to a `Service`, the waypoint will also apply routing and load balancing.
By default, a `Service` will simply route to itself, load balancing across its endpoints.
This can be overridden with Routes for that `Service`.

For example, the below policy will ensure that requests to the `echo` service are forwarded to `echo-v1`:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: echo
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: echo
  rules:
  - backendRefs:
    - name: echo-v1
      port: 80
{{< /text >}}

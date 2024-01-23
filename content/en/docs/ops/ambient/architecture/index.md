---
title: Ambient Mesh Architecture
description: Deep dive into ambient mesh architecture.
weight: 20
owner: istio/wg-networking-maintainers
test: n/a
---

This page is under construction.

## Differences from sidecar architecture

## Traffic routing

In {{< gloss "ambient" >}}ambient mode{{< /gloss >}}, workloads can fall into 3 categories:
1. **Uncaptured:** this is a standard pod without any mesh features enabled.
1. **Captured:** this is a pod that has traffic intercepted by {{< gloss >}}ztunnel{{< /gloss >}}. Pods can be captured by setting the `istio.io/dataplane-mode=ambient` label on a namespace.
1. **Waypoint enabled:** this is a pod that is "Captured" *and* has a {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} deployed.
  A waypoint will, by default, apply to all pods in the same namespace.
  It can optionally be set to apply to only a specific service account with the `istio.io/for-service-account` annotation on the `Gateway`.
  If there is both a namespace waypoint and service account waypoint, the service account waypoint takes precedence.

Depending on which category a workload is in, the request path will be different.

### Ztunnel routing

#### Outbound

When a captured pod makes an outbound request, it will be transparently redirected to ztunnel which will determine where and how to forward the request.
In general, the traffic routing behaves just like Kubernetes default traffic routing;
requests to a `Service` will be sent to an endpoint within the `Service` while requests directly to a `Pod` IP will go directly to that IP.

However, depending on the destination's capabilities, different behavior will occur.
If the destination is also captured, or otherwise has Istio proxy capabilities (such as a sidecar), the request will be upgraded to an encrypted {{< gloss "HBONE" >}}HBONE tunnel{{< /gloss >}}.
If the destination has a waypoint proxy, in addition to being upgraded to HBONE, the request will instead be forwarded to that waypoint.

Note that in the case of a request to a `Service`, a specific endpoint will be selected to determine if it has a waypoint.
However, if it *has* a waypoint, the request will be sent with a target destination of the `Service`, not the selected endpoint.
This allows the waypoint to apply service-oriented policies to the traffic.
In the rare case that a `Service` has a mix of waypoint enabled and non-enabled endpoints, some requests would be sent to a waypoint while other requests to the same service would not.

#### Inbound

When a captured pod receives an inbound request, it will be transparently redirected to ztunnel.
When ztunnel receives the request, it will apply Authorization Policies and forward the request only if the request meets the policies.

A pod can receive HBONE traffic or plaintext traffic.
By default, both will be accepted by ztunnel.
Because plaintext requests will have no peer identity when Authorization Policies are evaluated,
a user can set a policy requiring an identity (either *any* identity, or a specific one) to block all plaintext traffic.

When the destination is waypoint enabled, all requests *must* go through the waypoint where policy is enforced.
The ztunnel will make sure this occurs.
However, there is an edge case: a well behaving HBONE client (such as another ztunnel or Istio sidecar) would know to send to the waypoint, but other clients
(such as a workload outside of the mesh) likely would not know anything about waypoint proxies and send requests directly.
When these direct calls are made, the ztunnel will "hairpin" the request to its own waypoint to ensure policies are properly enforced.

### Waypoint routing

A waypoint exclusively receives HBONE requests.
Upon receiving a request, the waypoint will ensure it is targeting either a `Pod` that it manages or a `Service` that contains a `Pod` it manages.

For either type of request, the waypoint will enforce policies (such as `AuthorizationPolicy`, `WasmPlugin`, `Telemetry`, etc) before forwarding.

For direct requests to a `Pod`, the requests are simply forwarded directly after policy is applied.

For requests to a `Service`, the waypoint will also apply routing and load balancing.
By default, a `Service` will simply route to itself, load balancing across its endpoints.
This can be overridden with Routes for that `Service`.

For example, the below policy will ensure that requests to the `echo` service are forwarded to `echo-v1`:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1beta1
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

## Security

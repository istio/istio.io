---
title: Ambient Mesh Architecture
description: Deep dive into ambient mesh architecture.
force_inline_toc: true
weight: 3
owner: istio/wg-networking-maintainers
test: n/a
---

This page is under construction.

## Differences from sidecar architecture

## Traffic routing

In ambient mode, workloads can fall into 3 categories:
* Uncaptured: this is a standard pod without any mesh features enabled
* Captured: this is a pod that has traffic intercepted by `ztunnel`. Pods can be captured by setting the `istio.io/dataplane-mode=ambient` label on a namespace.
* Waypoint enabled: this is a pod that is "Captured" *and* has a waypoint proxy deployed.
  A waypoint will, by default, apply to all pods in the same namespace.
  It can optionally be set to apply to only a specific namespace with the `istio.io/for-service-account` annotation on the `Gateway`.
  If there is both a namespace waypoint and service account waypoint, the service account waypoint takes precedence.

Depending on which category a workload is in, the request path will be different.

### Ztunnel routing

#### Outbound

When a captured pod makes an outbound request, it will be transparently redirected to `ztunnel` which will determine where and how to forward the request.
In general, the traffic routing behaves just like Kubernetes default traffic routing.
Requests to a `Service` will be sent to an endpoint within the `Service`, and requests directly to a `Pod` IP would be go directly to that `Pod` IP.

However, depending on the destination's capabilities, different behavior will occur.
If the destination is also captured, or otherwise has Istio proxy capabilities (such as a sidecar), the request will be upgraded to an encrypted HBONE tunnel.
If the destination has a waypoint proxy, in addition to being upgraded to HBONE, the request will instead be forwarded to that waypoint.

Note that in the case of a request to a `Service`, a specific endpoint will be selected to determine if it has a waypoint.
However, if it *has* a waypoint, the request will be sent with a target destination of the `Service`, not the selected endpoint.
This allows the waypoint to apply service-oriented policies to the traffic.
In the rare case that a `Service` has a mix of waypoint enabled and non-enabled endpoints, this would mean that some of our requests would be sent to a waypoint while others would not.

#### Inbound

When a captured pod receives an inbound request, it will be transparently redirected to `ztunnel`.
When `ztunnel` receives the request, it will apply Authorization Policies and forward the request only if the request meets the policies.

A pod can receive HBONE traffic or plaintext traffic.
By default, both will be accepted by `ztunnel`.
However, when evaluating Authorization Policies for plaintext traffic, the peer identity would be unset.
This allows a user to set a policy requiring an identity (either *any* identity, or a specific one) to block all plaintext traffic.

When the destination is waypoint enabled, all requests *must* go through the waypoint, where policy is enforced.
The `ztunnel` will enforce this occurs.
However, there is an edge case: a well behaving HBONE client (such as another ztunnel or Istio sidecar) would know to send to the waypoint, but for other clients
(such as a workload outside of the mesh) likely would not know anything about waypoint proxies and send requests directly.
When these direct calls are made, the ztunnel will "hairpin" the request to its own waypoint to ensure policies are properly enforced.

### Waypoint routing

A waypoint exclusively receives HBONE requests.
Upon receiving a request, the waypoint will ensure it is targeting either a `Pod` that it manages or a `Service` that contains a `Pod` it manages.

For either type of request, the waypoint will enforce policies (such as `AuthorizationPolicy`, `WasmPlugin`, `Telemetry`, etc) before forwarding.

For requests to `Pod`s directly, these are simply forwarded directly after policy is applied.

For requests to `Service`s, the waypoint will apply routing and load balancing.
By default, a `Service` will simply route to itself, load balancing across its endpoints.
This can be overridden with Routes for that `Service`.

For example, the below policy would ensure requests to `echo` were actually forwarded to `echo-v1`:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: echo
spec:
  parentRefs:
  - kind: Service
    name: echo
  rules:
  - backendRefs:
    - name: echo-v1
      port: 80
{{< /text >}}

## Security

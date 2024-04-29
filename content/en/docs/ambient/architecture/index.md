---
title: Architecture
description: A deep dive into the architecture of ambient mode.
weight: 20
aliases:
  - /docs/ops/ambient/architecture
  - /latest/docs/ops/ambient/architecture
owner: istio/wg-networking-maintainers
test: n/a
---

## Ambient APIs

### Labels

You can use the following labels to enroll your namespace to ambient, enroll your resource to use a waypoint and specify the capture scope of your waypoint.

|  Name  | Feature Status | Scope | Description |
| --- | --- | --- | --- | --- |
| `istio.io/dataplane-mode` | Beta | Namespace |  Specifies the data plane mode, valid value: `ambient`. |
| `istio.io/use-waypoint` | Beta | Namespace or Service or Pod or WorkloadEntry or ServiceEntry | Enrolls your resource to use a given waypoint, valid value: `#none` or `{namespace}/{waypoint-name}` |
| `istio.io/waypoint-for` | Alpha | Gateway or GatewayClass | Specifies the waypoint's capture scope, valid value: `service` or `none` or `workload` or `all`. The default value is `service`. |

### Policy attachment to waypoints

You can attach Layer 7 policies (such as `AuthorizationPolicy`, `RequestAuthentication`, `Telemetry`, `WasmPlugin`) to your waypoint using `targetRef`.

1. To attach the entire waypoint, set `Gateway` as the `targetRef` value. The example below shows how to attach the policy
to entire waypoint for the `default` namespace:

```
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: productpage-viewer
  namespace: default
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: waypoint
```

1. To attach a given service within the waypoint, set `Service` as the `targetRef` value. The example below shows how to attach the policy
to the `productpage` service in the `default` namespace:

```
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: productpage-viewer
  namespace: default
spec:
  targetRef:
    kind: Service
    group: ""
    name: productpage
```

## Traffic routing

In {{< gloss "ambient" >}}ambient mode{{< /gloss >}}, workloads can fall into 3 categories:
1. **Uncaptured:** this is a standard pod without any mesh features enabled.
1. **Captured:** this is a pod that has traffic intercepted by {{< gloss >}}ztunnel{{< /gloss >}}. A pod's catpured mode can be enabled by setting the `istio.io/dataplane-mode=ambient` label on its namespace, which enables all pods' captured mode for that namespace.
1. **Waypoint enabled:** this is a pod that is "Captured" *and* has a {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} deployed.
  If a namespace is labelled with `istio.io/use-waypoint` with its default waypoint (for example `istio.io/use-waypoint: waypoint`), the waypoint will apply to all pods in the namespace.
  The `istio.io/use-waypoint` label can optionally be set to apply to only a specific service or pod with its desired waypoint (for example, `istio.io/use-waypoint: my-waypoint`).
  If the `istio.io/use-waypoint` label exists on the namespace and/or service and/or pod, the pod waypoint takes precedence over the service waypoint, which takes precedence over the namespace waypoint.

Depending on which category a workload is in, the request path will be different.

### Ztunnel routing

#### Outbound

When a captured pod makes an outbound request, it will be transparently redirected to ztunnel which will determine where and how to forward the request.
In general, the traffic routing behaves just like Kubernetes default traffic routing;
requests to a `Service` will be sent to an endpoint within the `Service` while requests directly to a `Pod` IP will go directly to that IP.

However, depending on the destination's capabilities, different behavior will occur.
If the destination is also captured, or otherwise has Istio proxy capabilities (such as a sidecar), the request will be upgraded to an encrypted {{< gloss "HBONE" >}}HBONE tunnel{{< /gloss >}}.
If the destination has a waypoint proxy, in addition to being upgraded to HBONE, the request will instead be forwarded to that waypoint.

Note that in the case of a request to a `Service`, if the service *has* a waypoint, the request will be sent to its waypoint to enforce service-oriented policies to the traffic.
Similarly, in the case of a request to a `Pod` IP, if the pod *has* a waypoint, the request will be sent to its waypoint to enforce pod-oriented policies to the traffic.
In the rare case that a `Service` has a mix of waypoint enabled and non-enabled endpoints, some requests would be sent to a waypoint while other requests to the same service would not.

#### Inbound

When a captured pod receives an inbound request, it will be transparently redirected to ztunnel.
When ztunnel receives the request, it will apply Authorization Policies and forward the request only if the request meets the policies.

A pod can receive HBONE traffic or plaintext traffic.
By default, both will be accepted by ztunnel.
Because plaintext requests will have no peer identity when Authorization Policies are evaluated,
a user can set a policy requiring an identity (either *any* identity, or a specific one) to block all plaintext traffic.

When the destination is waypoint enabled, if the source is `captured` by its ztunnel, the ztunnel ensures the request **must** go through
the waypoint where policy is enforced. However, a workload outside of the mesh doesn't know anything about waypoint proxies and it sends
requests directly to the destination without going through any waypoint proxies even if the destination is waypoint enabled.
Currently, traffic from sidecars and gateways won't go through the waypoint and they will be made aware of waypoint proxies
in a future release.

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

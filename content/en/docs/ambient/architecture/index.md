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

You can use the following labels to add your resource to the mesh, use a waypoint for traffic to your resource, and control what traffic is sent to the waypoint.

|  Name  | Feature Status | Resource | Description |
| --- | --- | --- | --- | --- |
| `istio.io/dataplane-mode` | Beta | `Namespace` |  Add your resource to the mesh, valid value: `ambient`. |
| `istio.io/use-waypoint` | Beta | `Namespace` or `Service` or `Pod` | Use a waypoint for traffic to the labeled resource for L7 policy enforcement, valid values: `{waypoint-name}`, `{namespace}/{waypoint-name}`, or `#none` |
| `istio.io/waypoint-for` | Alpha | `Gateway` | Specifies what types of endpoints the waypoint will process traffic for, valid value: `service` or `none` or `workload` or `all`. This label is optional and the default value is `service`. |

In order for your `istio.io/use-waypoint` label value to be effective, you have to ensure the waypoint is configured for the endpoint which is using it. By default waypoints accept traffic for service endpoints. For example, when you label a pod to use a specific waypoint via the `istio.io/use-waypoint` label, the waypoint should be labeled `istio.io./waypoint-for` with the value `workload` or `all`.

### Layer 7 policy attachment to waypoints

You can attach Layer 7 policies (such as `AuthorizationPolicy`, `RequestAuthentication`, `Telemetry`, `WasmPlugin`, etc) to your waypoint using `targetRefs`.

- To attach a L7 policy to the entire waypoint, set `Gateway` as the `targetRefs` value. The example below shows how to attach the `viewer` policy
to the waypoint named `waypoint` for the `default` namespace:

    {{< text yaml >}}
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: viewer
      namespace: default
    spec:
      targetRefs:
      - kind: Gateway
        group: gateway.networking.k8s.io
        name: waypoint
    {{< /text >}}

- To attach a L7 policy to a specific service within the waypoint, set `Service` as the `targetRefs` value. The example below shows how to attach
the `productpage-viewer` policy to the `productpage` service in the `default` namespace:

    {{< text yaml >}}
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: productpage-viewer
      namespace: default
    spec:
      targetRefs:
      - kind: Service
        group: ""
        name: productpage
    {{< /text >}}

## Traffic routing

In {{< gloss "ambient" >}}ambient mode{{< /gloss >}}, workloads can fall into 3 categories:
1. **Out of Mesh:** this is a standard pod without any mesh features enabled.
1. **In Mesh:** this is a pod that has traffic intercepted at the Layer 4 level by {{< gloss >}}ztunnel{{< /gloss >}}. In this mode, L4 policies can be enforced for pod traffic. This mode can be enabled for a pod by setting the `istio.io/dataplane-mode=ambient` label on the pod's namespace. This will enable *in mesh* mode for all pods in that namespace.
1. **Waypoint enabled:** this is a pod that is "in mesh" *and* has a {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} deployed. To enforce L7 policies, add the `istio.io/use-waypoint` label to your resource to use waypoint for the labeled resource.
  - If a namespace is labeled with `istio.io/use-waypoint` with its default waypoint for the namespace, the waypoint will apply to all pods in the namespace.
  - The `istio.io/use-waypoint` label can also be set on individual services or pods when using a waypoint for the entire namespace is not desired.
  - If the `istio.io/use-waypoint` label exists on both a namespace and a service, the service waypoint takes
  precedence over the namespace waypoint as long as the service waypoint can handle service or all traffic.
  Similarly, a label on a pod will take precedence over a namespace label.

Depending on which category a workload is in, the request path will be different.

### Ztunnel routing

#### Outbound

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

#### Inbound

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

### Waypoint routing

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

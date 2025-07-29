---
title: Use Layer 7 features
description: Supported features when using a L7 waypoint proxy.
weight: 50
owner: istio/wg-networking-maintainers
test: no
---

By adding a waypoint proxy to your traffic flow you can enable more of [Istio's features](/docs/concepts). Waypoints are configured using {{< gloss "gateway api" >}}Gateway API{{< /gloss >}}.

{{< warning >}}
The VirtualService and EnvoyFilter APIs are not supported in waypoints. [Read more below](/docs/ambient/usage/l7-features/#unsupported-apis-with-waypoints).
{{< /warning >}}

## Route and policy attachment

Gateway API defines the relationship between objects (such as routes and gateways) in terms of *attachment*.

* Route objects (such as [HTTPRoute](https://gateway-api.sigs.k8s.io/api-types/httproute/)) include a way to reference the **parent** resources it wants to attach to.
* Policy objects are considered [*metaresources*](https://gateway-api.sigs.k8s.io/geps/gep-713/): objects that augments the behavior of a **target** object in a standard way.

The tables below show the type of attachment that is configured for each object.

## Traffic routing

With a waypoint proxy deployed, you can use the following traffic route types:

|  Name  | Feature Status | Attachment |
| --- | --- | --- |
| [`HTTPRoute`](https://gateway-api.sigs.k8s.io/guides/http-routing/) | Stable | `parentRefs` |
| [`GRPCRoute`](https://gateway-api.sigs.k8s.io/guides/grpc-routing/) | Stable | `parentRefs` |
| [`TLSRoute`](https://gateway-api.sigs.k8s.io/guides/tls) | Alpha | `parentRefs` |
| [`TCPRoute`](https://gateway-api.sigs.k8s.io/guides/tcp/) | Alpha | `parentRefs` |

(TLS and TCP routing are stable features in Istio, but support for these objects remains at Alpha because the Gateway API objects are still in the experimental channel.)

Refer to the [traffic management](/docs/tasks/traffic-management/) documentation to see the range of features that can be implemented using these routes.

## Security

Without a waypoint installed, you can only use [Layer 4 security policies](/docs/ambient/usage/l4-policy/). By adding a waypoint, you gain access to the following policies:

|  Name  | Feature Status | Attachment |
| --- | --- | --- |
| [`AuthorizationPolicy`](/docs/reference/config/security/authorization-policy/) (including L7 features) | Stable | `targetRefs` |
| [`RequestAuthentication`](/docs/reference/config/security/request_authentication/) | Beta | `targetRefs` |

### Considerations for authorization policies {#considerations}

In ambient mode, authorization policies can either be *targeted* (for ztunnel enforcement) or *attached* (for waypoint enforcement). For an authorization policy to be attached to a waypoint it must have a `targetRef` which refers to the waypoint, or a Service which uses that waypoint.

The ztunnel cannot enforce L7 policies. If a policy with rules matching L7 attributes is targeted with a workload selector (rather than attached with a `targetRef`), such that it is enforced by a ztunnel, it will fail safe by becoming a `DENY` policy.

See [the L4 policy guide](/docs/ambient/usage/l4-policy/) for more information, including when to attach policies to waypoints for TCP-only use cases.

## Observability

The [full set of Istio traffic metrics](/docs/reference/config/metrics/) are exported by a waypoint proxy.

## Extension

As the waypoint proxy is a deployment of {{< gloss >}}Envoy{{< /gloss >}}, some of the extension mechanisms that are available for Envoy in {{< gloss "sidecar">}}sidecar mode{{< /gloss >}} are also available to waypoint proxies.

|  Name  | Feature Status | Attachment |
| --- | --- | --- |
| `WasmPlugin` † | Alpha | `targetRefs` |

† [Read more on how to extend waypoints with WebAssembly plugins](/docs/ambient/usage/extend-waypoint-wasm/).

Extension configurations are considered policy by the Gateway API definition.

## Scoping routes or policies

A route or policy can be scoped to apply to all traffic traversing a waypoint proxy, or only specific services.

### Attach to the entire waypoint proxy

To attach a route or a policy to the entire waypoint — so that it applies to all traffic enrolled to use it — set `Gateway` as the `parentRefs` or `targetRefs` value, depending on the type.

To scope an `AuthorizationPolicy` policy to apply to the waypoint named `default` for the `default` namespace:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: view-only
  namespace: default
spec:
  targetRefs:
  - kind: Gateway
    group: gateway.networking.k8s.io
    name: default
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["default", "istio-system"]
    to:
    - operation:
        methods: ["GET"]
{{< /text >}}

### Attach to a specific service

You can also attach a route to one or more specific services within the waypoint. Set `Service` as the `parentRefs` or `targetRefs` value, as appropriate.

To apply the `reviews` HTTPRoute to the `reviews` service in the `default` namespace:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
  namespace: default
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
{{< /text >}}

## Unsupported APIs with waypoints

Some legacy Istio APIs are deliberately not supported by waypoints in ambient mode.  These APIs can still be used with [Istio Gateways](/docs/tasks/traffic-management/ingress/ingress-control/).

### VirtualService

Istio's legacy traffic routing API is not supported for configuring waypoint traffic routing, though it works in some circumstances.

Any use of VirtualService with waypoints is considered Alpha, and may be subject to change in future releases.
Istio's maintainers do not intend to remove this support, but will not be progressing it to [any further feature phase](/docs/releases/feature-stages).

#### Migrating from VirtualService to Gateway API routes

[Only a single VirtualService](/docs/reference/config/analysis/ist0109/) can be used for mesh traffic matching a certain hostname. However, multiple Gateway API routes can refer to the same host.

This is especially relevant when you are migrating from VirtualService to Gateway API routes. If you create one or more HTTPRoutes which specify a Service that is also in use with a VirtualService, the HTTPRoute/s will apply and the VirtualService will not.

To avoid this situation, users migrating from sidecars should look to convert their VirtualService configuration to Gateway API routes. The [ingress2gateway](https://github.com/kubernetes-sigs/ingress2gateway/) project has limited support for this use case. Caution is advised, especially for users who use [subset routing](/docs/concepts/traffic-management/#destination-rules)

#### Using features that are not in Gateway API

A small number of Istio's features cannot currently be expressed in Gateway API: for example, [fault injection](/docs/tasks/traffic-management/fault-injection/) and [direct response](/docs/reference/config/networking/virtual-service/#HTTPDirectResponse). It is technically possible to use VirtualService for these use cases, as long as the configured `hosts` do not conflict with the `parentRefs` of any Gateway API route as mentioned above.

#### DestinationRule subsets

Gateway API has no ability to address [subsets](/docs/reference/config/networking/destination-rule/#Subset). Instead, you must define additional Services which have a more granular selector than the original.

The other features of DestinationRule are supported.

#### Legacy Istio gateways

Istio Gateways configured with VirtualService (i.e. where the `gateways` field refers to a named ingress gateway) can safely be mixed with waypoints which are configured with Gateway API routes.

### EnvoyFilter

EnvoyFilter is Istio's break-glass API for advanced configuration of Envoy proxies. Please note that **EnvoyFilter is not currently supported for any existing Istio version with waypoint proxies**. While it may be possible to use EnvoyFilter with waypoints in limited scenarios, its use is not supported, and is actively discouraged by the maintainers. The alpha API may break in future releases as it evolves. We expect official support will be provided at a later date.

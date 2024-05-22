---
title: Use Layer 7 features
description: Supported features when using a L7 waypoint proxy.
weight: 50
owner: istio/wg-networking-maintainers
test: no
---

By adding a waypoint proxy to your traffic flow you can enable more of [Istio's features](/docs/concepts).

Ambient mode supports configuring waypoints using the Kubernetes Gateway API. Configurations that apply to a Gateway API are called _policies_.

{{< warning >}}
The Istio classic traffic management APIs (virtual service, destination rules etc) remain at Alpha in the ambient data plane mode.

Mixing Istio classic API and Gateway API configuration is not supported, and will lead to undefined behavior.
{{< /warning >}}

## Traffic routing

With a waypoint proxy deployed, you can use the following API types:

|  Name  | Feature Status | Attachment |
| --- | --- | --- |
| `HTTPRoute` | Beta | `parentRefs` |
| `TCPRoute` | Alpha | `parentRefs` |
| `TLSRoute` | Alpha | `parentRefs` |

Refer to the [traffic management](/docs/tasks/traffic-management/) documentation to see the range of features that can be implemented using these routes.

## Security

Without a waypoint installed, you can only use [Layer 4 security policies](/docs/ambient/usage/l4-policy/). By adding a waypoint, you gain access to the following policies:

|  Name  | Feature Status | Attachment |
| --- | --- | --- |
| [`AuthorizationPolicy`](/docs/reference/config/security/authorization-policy/) (including L7 features) | Beta | `targetRefs` |
| [`RequestAuthentication`](/docs/reference/config/security/request_authentication/) | Beta | `targetRefs` |

### Considerations for authorization policies

Authorization policies whose [conditions](/docs/reference/config/security/conditions/) only target Layer 4 (TCP) will either be [enforced by the ztunnel or the waypoint](/docs/ambient/usage/l4-policy#considerations) depending on where the policy is targeted for attachment.

In a scenario where a policy contains conditions that match L7 attributes (for example, HTTP verbs), a waypoint proxy is **required**. It is important to understand that ztunnel cannot meaningfully enforce any policy that requires L7 parsing. If an authorization policy has been configured that requires any traffic processing beyond L4, and if no waypoint proxies are configured for the destination of the traffic, then **the ztunnel proxy will DENY all traffic** as a defensive move.

Authorisation policuies

When the following conditions are true:

1. The policy enforces [conditions](/docs/reference/config/security/conditions/) for HTTP
1. The source pod is a normal pod which has ztunnel enabled.
1. The waypoint is configured with the `istio.io/waypoint-for` label set to `service`.

Policy enforcement will be applied as follows:

Attachment Style | Scope | Waypoint present? | | Enforced by | Allowed? | Source identity
| --- | --- | --- | --- | --- | -- | -- |
| _empty †_ | Namespace | no | ⇒ | destination ztunnel | DENY | n/a |
| _empty †_ | Namespace | yes | ⇒ | destination ztunnel | DENY | n/a |
| Selector | Pod | no | ⇒ | destination ztunnel | DENY | n/a |
| Selector | Pod | yes | ⇒ | destination ztunnel | DENY | n/a |
| `targetRefs` | Service | yes | ⇒ | waypoint | per policy | client pod |
| `targetRefs` | Gateway | yes | ⇒ | waypoint | per policy | client pod |

*† If no Selector or `targetRef` is specified, the policy is namespace scoped.*

## Observability

The [full set of Istio traffic metrics](/docs/reference/config/metrics/) are exported by a waypoint proxy.

## Extension

As the waypoint proxy is a deployment of {{< gloss >}}Envoy{{< /gloss >}}, the extension mechanisms that are available for Envoy in {{< gloss >}}sidecar{{< /gloss >}} mode are also available to waypoint proxies.

|  Name  | Feature Status | Attachment |
| --- | --- | --- |
| `WasmPlugin` | Alpha | `targetRefs` |
| `EnvoyFilter` | Alpha | `targetRefs` |

Read more on how to extend waypoints with Wasm plugins [here](/docs/ambient/usage/extend-waypoint-wasm/).

## Targeting policies or routing rules

### Attach to the entire waypoint proxy

To attach a policy or routing rule to the entire waypoint — so that it applies to all traffic enrolled to use it — set `Gateway` as the `parentRefs` or `targetRefs` value, depending on the type.

For example, to apply an `AuthorizationPolicy` policy to the waypoint named `waypoint` for the `default` namespace:

{{< text bash >}}
$ kubectl apply -f - <<EOF
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
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["default", "istio-system"]
    to:
    - operation:
        methods: ["GET"]
EOF
{{< /text >}}

### Attach to a specific service

You can also attach a policy or routing rule to a specific service within the waypoint. Set `Service` as the `parentRefs` or `targetRefs` value, as appropriate.

The example below shows how to apply the `reviews` HTTPRoute to the `reviews` service in the `default` namespace:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: reviews
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
EOF
{{< /text >}}

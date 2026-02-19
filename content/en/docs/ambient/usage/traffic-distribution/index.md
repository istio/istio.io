---
title: Traffic Distribution
description: Control how traffic is distributed to endpoints in ambient mode.
weight: 35
owner: istio/wg-networking-maintainers
test: no
---

The `networking.istio.io/traffic-distribution` annotation controls how {{< gloss >}}ztunnel{{< /gloss >}} distributes traffic across available endpoints. This is useful for keeping traffic local to reduce latency and cross-zone costs.

## Supported values

| Value | Behavior |
| --- | --- |
| `PreferSameZone` | Prioritize endpoints by proximity: network, region, zone, then subzone. Traffic goes to the closest healthy endpoints first. |
| `PreferClose` | Deprecated alias for `PreferSameZone`. See [Kubernetes enhancement proposal 3015](https://github.com/kubernetes/enhancements/tree/master/keps/sig-network/3015-prefer-same-node). |
| `PreferSameNode` | Prefer endpoints on the same node as the client. |
| (unset) | No locality preference. Traffic is distributed across all healthy endpoints. |

## Applying the annotation

The annotation can be applied to:

- **`Service`**: Affects traffic to that specific service
- **`Namespace`**: Sets the default for all services in the namespace
- **`ServiceEntry`**: Affects traffic to external services

### Precedence

When multiple levels are configured, the most specific wins:

1. `spec.trafficDistribution` field (`Service` only)
1. Annotation on `Service`/`ServiceEntry`
1. Annotation on `Namespace`
1. Default behavior (no locality preference)

## Examples

### Per-service configuration

Apply to a single service:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    networking.istio.io/traffic-distribution: PreferSameZone
spec:
  selector:
    app: my-app
  ports:
  - port: 80
{{< /text >}}

### Namespace-wide configuration

Apply to all services in a namespace:

{{< text yaml >}}
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
  annotations:
    networking.istio.io/traffic-distribution: PreferSameZone
{{< /text >}}

Services in the namespace inherit this setting unless they have their own annotation.

### Override namespace default

A service can override the namespace setting with its own annotation:

{{< text yaml >}}
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
  annotations:
    networking.istio.io/traffic-distribution: PreferSameZone
---
apiVersion: v1
kind: Service
metadata:
  name: different-service
  namespace: my-namespace
  annotations:
    networking.istio.io/traffic-distribution: PreferSameNode
spec:
  selector:
    app: different-app
  ports:
  - port: 80
{{< /text >}}

Services without an annotation inherit the namespace setting.

## Behavior

### `PreferSameZone`

With `PreferSameZone`, ztunnel categorizes endpoints by locality and routes to the closest healthy ones:

1. Same network, region, zone, and subzone
1. Same network, region, and zone
1. Same network and region
1. Same network
1. Any available endpoint

If all endpoints in a closer locality become unhealthy, traffic automatically fails over to the next level.

For example, a service with endpoints in zones `us-west`, `us-west`, and `us-east`:

- Client in `us-west` sends all traffic to the two `us-west` endpoints
- If one `us-west` endpoint fails, traffic goes to the remaining `us-west` endpoint
- If both `us-west` endpoints fail, traffic fails over to `us-east`

### `PreferSameNode`

With `PreferSameNode`, ztunnel prefers endpoints running on the same Kubernetes node as the client. This minimizes network hops and latency for node-local communication.

## Relationship to Kubernetes `trafficDistribution`

Kubernetes 1.31 introduced the [`spec.trafficDistribution`](https://kubernetes.io/docs/concepts/services-networking/service/#traffic-distribution) field on `Service`s. This Istio annotation provides the same functionality with additional benefits:

| | `spec.trafficDistribution` | Annotation |
| --- | --- | --- |
| Kubernetes version | 1.31+ | Any |
| `Service` | Yes | Yes |
| `ServiceEntry` | No | Yes |
| `Namespace` | No | Yes |

When both the spec field and annotation are set on a `Service`, the spec field takes precedence.

Waypoints automatically configure this annotation.

## See also

- [Locality Load Balancing](/docs/tasks/traffic-management/locality-load-balancing/) for sidecar-based locality routing
- [Annotation reference](/docs/reference/config/annotations/#NetworkingTrafficDistribution)

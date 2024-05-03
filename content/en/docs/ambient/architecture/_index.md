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

To enforce L7 policies, add the `istio.io/use-waypoint` label to your resource to use waypoint for the labeled resource.
  - If a namespace is labeled with `istio.io/use-waypoint` with its default waypoint for the namespace, the waypoint will apply to all pods in the namespace.
  - The `istio.io/use-waypoint` label can also be set on individual services or pods when using a waypoint for the entire namespace is not desired.
  - If the `istio.io/use-waypoint` label exists on both a namespace and a service, the service waypoint takes
  precedence over the namespace waypoint as long as the service waypoint can handle service or all traffic.
  Similarly, a label on a pod will take precedence over a namespace label

### Labels {#ambient-labels}

You can use the following labels to add your resource to the {{< gloss >}}ambient{{< /gloss >}} mesh and manage L4 traffic with the ambient {{< gloss >}}data plane{{< /gloss >}}, use a waypoint to enforce L7 policy for your resource, and control how traffic is sent to the waypoint.

|  Name  | Feature Status | Resource | Description |
| --- | --- | --- | --- |
| `istio.io/dataplane-mode` | Beta | `Namespace` or `Pod` (latter has precedence) |  Add your resource to an ambient mesh. <br><br> Valid values: `ambient` or `none`. |
| `istio.io/use-waypoint` | Beta | `Namespace`, `Service` or `Pod` | Use a waypoint for traffic to the labeled resource for L7 policy enforcement. <br><br> Valid values: `{waypoint-name}`, `{namespace}/{waypoint-name}`, or `#none` (with hash). |
| `istio.io/waypoint-for` | Alpha | `Gateway` | Specifies what types of endpoints the waypoint will process traffic for. <br><br> Valid values: `service`, `workload`, `none` or `all`. This label is optional and the default value is `service`. |

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

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

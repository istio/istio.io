---
title: Layer 7 Networking & Services with Waypoint Proxies
description: Gain the full set of Istio feature with optional waypoint proxies.
weight: 2
aliases:
  - /docs/ops/ambient/usage/waypoint
  - /latest/docs/ops/ambient/usage/waypoint
owner: istio/wg-networking-maintainers
test: no
---

Ambient splits Istio’s functionality into two distinct layers, a secure overlay layer and a Layer 7 processing layer.
The waypoint proxy is an optional component that is Envoy-based and handles L7 processing for different resources.
What is unique about the waypoint proxy is that it runs outside of the application pod. A waypoint proxy can install,
upgrade, and scale independently from the application, as well as reduce operational costs. When deploying a waypoint,
you can configure the waypoint to process traffic for different resource types such as `service` or `workload` or `all`.

## Do you need a waypoint proxy?


## Deploy a waypoint proxy


## Use a waypoint proxy


## Attach L7 policies to the waypoint proxy


## Debug your waypoint proxy

---
title: Install Multicluster
description: Install an Istio mesh in ambient mode across multiple Kubernetes clusters.
weight: 40
keywords: [kubernetes,multicluster,ambient]
simple_list: true
content_above: true
test: table-of-contents
owner: istio/wg-environments-maintainers
next: /docs/ambient/install/multicluster/before-you-begin
---

Follow this guide to install an Istio {{< gloss "ambient" >}}ambient service mesh{{< /gloss >}}
that spans multiple {{< gloss "cluster" >}}clusters{{< /gloss >}}.

## Current Status and Limitations

{{< warning >}}
While Ambient **multi-network multicluster** has reached beta status and considered production
ready, there are still known limitations that apply to ambient multicluster deployment. We
intend to address those limitations in the future Istio releases, in the meantime check the
list below to see if the known limitations are applicable to your use case.
{{< /warning >}}

Before proceeding with ambient multicluster installation, it's critical to understand
the current state and limitations of this feature.

### Known Limitations

#### Network Topology Restrictions

Multicluster single-network configurations are untested, and may be broken:

- Use caution when deploying ambient across clusters that share the same network
- Only multi-network configurations are supported

#### Control Plane Limitations

Primary remote configuration is not currently supported:

- You can only have multiple primary clusters
- Configurations with one or more remote clusters will not work correctly

#### Waypoint Requirements

Universal waypoint deployments are assumed across clusters:

- All clusters must have identically named waypoint deployments
- Waypoint configurations must be synchronized manually across clusters (e.g. using Flux, ArgoCD, or similar tools)
- Traffic routing relies on consistent waypoint naming conventions

#### Service Visibility and Scoping

Service scope configurations are not read from across clusters:

- Only uniform service scope configurations are supported - service scope must match across all
  clusters
- Only the local cluster's service scope configuration is used as the source of truth
- Remote cluster service scopes are not respected, which can lead to unexpected traffic behavior when
  the same service has different scopes in different clusters
- Cross-cluster service discovery may not respect intended service boundaries

If a service's waypoint is marked as global, that service will also be global:

- This can lead to unintended cross-cluster traffic in single-network multi-cluster deployments
- The solution to this issue is tracked [here](https://github.com/istio/istio/issues/57710)

#### Load Distribution on Remote Network

Traffic going to a remote network is not equally distributed between endpoints:

- When failing over to a remote network, a single endpoint on a remote network may get a
  disproportionate number of requests due to multiplexing of HTTP requests and connection pooling
- A very similar issue currently exists for sidecar mode as well
- The solution to this issue is tracked [here](https://github.com/istio/istio/issues/58039)

#### Gateway Limitations

Ambient east-west gateways currently only support meshed mTLS traffic:

- Cannot currently expose `istiod` across networks using ambient east-west gateways. You can still use a classic e/w gateway for this.

{{< tip >}}
As ambient multicluster matures, many of these limitations will be addressed.
Check the [Istio release notes](https://istio.io/latest/news/) for updates on
ambient multicluster capabilities.
{{< /tip >}}

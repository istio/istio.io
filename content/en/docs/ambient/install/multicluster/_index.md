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
**Ambient multicluster is currently in alpha status** and has significant limitations.
This feature is under active development and should not be used in production environments.
{{< /warning >}}

Before proceeding with ambient multicluster installation, it's critical to understand
the current state and limitations of this feature:

### Supported Configurations

Currently, ambient multicluster only supports:
Before proceeding with an ambient multicluster installation, it is critical to understand
the current state and limitations of this feature.

### Critical Limitations

#### Network Topology Restrictions

**Multi-cluster single-network configurations are untested, and may be broken**
  - Use caution when deploying ambient across clusters that share the same network
  - Only multi-network configurations are supported

#### Control Plane Limitations

**Primary remote configuration is not currently supported**
  - You can only have multiple primary clusters
  - Configurations with one or more remote clusters will not work correctly

#### Waypoint Requirements

**Universal waypoint deployments are assumed across clusters**
  - All clusters must have identically named waypoint deployments
  - Waypoint configurations must be synchronized manually across clusters (e.g. using Flux, ArgoCD, or similar tools)
  - Traffic routing relies on consistent waypoint naming conventions

#### Service Visibility and Scoping

**Service scope configurations are not read from across clusters**
  - Only the local cluster's service scope configuration is used as the source of truth
  - Remote cluster service scopes are not respected, which can lead to unexpected traffic behavior
  - Cross-cluster service discovery may not respect intended service boundaries

**If a service's waypoint is marked as global, that service will also be global**
  - This can lead to unintended cross-cluster traffic if not managed carefully

#### Gateway Limitations

**Ambient east-west gateways currently only support meshed mTLS traffic**
  - Cannot currently expose `istiod` across networks using ambient east-west gateways. You can still use a classic e/w gateway for this.

{{< tip >}}
As ambient multicluster matures, many of these limitations will be addressed.
Check the [Istio release notes](https://istio.io/latest/news/) for updates on
ambient multicluster capabilities.
{{< /tip >}}

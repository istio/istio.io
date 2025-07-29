---
title: Announcing Istio 1.26.3
linktitle: 1.26.3
subtitle: Patch Release
description: Istio 1.26.3 patch release.
publishdate: 2025-07-29
release: 1.26.3
aliases:
    - /news/announcing-1.26.3
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.26.2 and 1.26.3.

{{< relnote >}}

## Changes

- **Fixed** ambient index to filter configs by revision.
  ([Issue #56477](https://github.com/istio/istio/issues/56477))

- **Fixed** an issue where the `topology.istio.io/network` label was not properly skipped on the system namespace when `discoverySelectors` were in use.
  ([Issue #56687](https://github.com/istio/istio/issues/56687))

- **Fixed** an issue where the CNI plugin incorrectly handled pod deletion when the pod was not yet marked as enrolled in the mesh. In some cases, this could cause a pod, which had been deleted, to be included in the ZDS snapshot and never cleaned up. If this occurred, ztunnel would not be able to become ready.  ([Issue #56738](https://github.com/istio/istio/issues/56738))

- **Fixed** an issue where access logs were not updated when the referenced service was created later than the Telemetry resource.  ([Issue #56825](https://github.com/istio/istio/issues/56825))

- **Fixed** an issue where `ClusterTrustBundle` was not configured properly when `ENABLE_CLUSTER_TRUST_BUNDLE_API` was enabled.

- **Fixed** an issue where Istio access logs were never sent to the OTLP endpoint.  ([Issue 56825](https://github.com/istio/istio/issues/56825))

- **Fixed** an issue where high CPU usage could occur if an item was actively being worked on by a different worker until that worker was done with that item.

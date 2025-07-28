---
title: Announcing Istio 1.26.3
linktitle: 1.26.3
subtitle: Patch Release
description: Istio 1.26.3 patch release.
publishdate: 2020-07-29
release: 1.26.3
aliases:
    - /news/announcing-1.26.3
---

{{< warning >}}
This is an automatically generated rough draft of the release notes and has not yet been reviewed.
{{< /warning >}}

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.26.2 and 1.26.3.

{{< relnote >}}

## Changes

- **Fixed** ambient index to filter configs by revision.
  ([Issue #56477](https://github.com/istio/istio/issues/56477))

- **Fixed** ignoring the `topology.istio.io/network` label on the system namespace when `discoverySelectors` are in use.
  ([Issue #56687](https://github.com/istio/istio/issues/56687))

- **Fixed** CNI incorrectly handled pod deletion when the pod was not yet marked as enrolled in the mesh. In some cases, this could cause a pod which has been deleted to be included in the ZDS snapshot and never cleaned up. If this occurs ztunnel will not be able to become ready.  ([Issue #56738](https://github.com/istio/istio/issues/56738))

- **Fixed** an issue where access log not being updated when referenced service created later than the Telemetry resource.  ([Issue #56825](https://github.com/istio/istio/issues/56825))

- **Fixed** issues that `ClusterTrustBundle` was not working when `ENABLE_CLUSTER_TRUST_BUNDLE_API` is enabled.

- **Fixed** issue where Istio access logs are never sent to OTLP endpoint.  ([Issue 56825](https://github.com/istio/istio/issues/56825))

- **Fixed** issue with `istiod` causing high CPU usage.  ([PR 56798](https://github.com/istio/istio/pull/56798))

- **Added** test flag which allows the use of the `AllowCRDsMismatch` parameter defined in the Gateway API Conformance suite. ([PR #56945](https://github.com/istio/istio/pull/56945))

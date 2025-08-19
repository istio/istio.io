---
title: Announcing Istio 1.16.2
linktitle: 1.16.2
subtitle: Patch Release
description: Istio 1.16.2 patch release.
publishdate: 2023-01-30
release: 1.16.2
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.16.1 and Istio 1.16.2.

{{< relnote >}}

## Changes

- **Added** `--revision` to `istioctl analyze` to specify a specific revision.
  ([Issue #38148](https://github.com/istio/istio/issues/38148))

- **Fixed** an issue with `istioctl install` failing when specifying `--revision default`.

- **Fixed** `istioctl verify-install` having inconsistent behavior between `--revision` not being specified and `--revision default`.

- **Fixed** an issue where Gateway API resources were not being handled correctly when namespace was selected or deselected with discovery selector or namespace label is changed, and when `ENABLE_ENHANCED_RESOURCE_SCOPING=true` is set.  ([Issue #42173](https://github.com/istio/istio/issues/42173))

- **Fixed** auto-passthrough gateways not getting XDS pushes on service updates if `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG` is enabled.

- **Fixed** an abnormal exit in pilot if `PortLevelSettings[].Port` is nil when setting traffic policy TLS mode.  ([Issue #42598](https://github.com/istio/istio/issues/42598))

- **Fixed** a bug that caused a namespace's network label to have a higher priority than the pod's network label.  ([Issue #42675](https://github.com/istio/istio/issues/42675))

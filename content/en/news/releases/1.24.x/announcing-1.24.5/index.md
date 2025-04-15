---
title: Announcing Istio 1.24.5
linktitle: 1.24.5
subtitle: Patch Release
description: Istio 1.24.5 patch release.
publishdate: 2025-04-14
release: 1.24.5
---


This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.24.4 and Istio 1.24.5.

{{< relnote >}}

## Changes

- **Fixed** corner cases where `istio-cni` might block its own upgrade. Added fallback logging (in case agent is down) to a fixed-size node-local log file.
  ([Issue #55215](https://github.com/istio/istio/issues/55215))

- **Fixed** an issue where validation webhook incorrectly reported a warning when a `ServiceEntry` configured `workloadSelector` with DNS resolution.
  ([Issue #50164](https://github.com/istio/istio/issues/50164))

- **Fixed** an issue where proxy memory goes up with gRPC streaming services.

- **Fixed** an issue causing changes to `ExternalName` services to sometimes be skipped due to a cache eviction bug.

- **Fixed** a regression where the SDS `ROOTCA` resource included only a single root certificate, even if the control plane
  was configured with both an active root and a passive root certificate that was introduced in 1.24.4.
  ([Issue #55793](https://github.com/istio/istio/issues/55793))

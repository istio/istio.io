---
title: Announcing Istio 1.25.2
linktitle: 1.25.2
subtitle: Patch Release
description: Istio 1.25.2 patch release.
publishdate: 2025-04-14
release: 1.25.2
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.25.1 and Istio 1.25.2.

{{< relnote >}}

## Changes

- **Added** an environment variable prefix `CA_HEADER_` (similar to `XDS_HEADER_`) that can be added to CA requests for different purposes, such as routing to appropriate external `istiod`s.
  Istio sidecar proxy, router, and waypoint now support this feature.  ([Issue #55064](https://github.com/istio/istio/issues/55064))

- **Fixed** corner cases where `istio-cni` might block its own upgrade. Added fallback logging (in case agent is down) to a fixed-size node-local log file.
  ([Issue #55215](https://github.com/istio/istio/issues/55215))

- **Fixed** an issue where `AuthorizationPolicy`'s `WaypointAccepted` status condition was not being updated to reflect the resolution of a `GatewayClass` target reference.

- **Fixed** an issue where `WaypointAccepted` status condition for `AuthorizationPolicies` that referenced a `GatewayClass` and did not reside in the root namespace was not being updated with the correct reason and message.

- **Fixed** an issue where proxy memory goes up with gRPC streaming services.

- **Fixed** an issue causing changes to `ExternalName` services to sometimes be skipped due to a cache eviction bug.

- **Fixed** a regression where the SDS `ROOTCA` resource included only a single root certificate, even if the control plane
  was configured with both an active root and a passive root certificate that was introduced in 1.25.1.
  ([Issue #55793](https://github.com/istio/istio/issues/55793))

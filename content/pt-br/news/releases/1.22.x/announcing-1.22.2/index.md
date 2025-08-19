---
title: Announcing Istio 1.22.2
linktitle: 1.22.2
subtitle: Patch Release
description: Istio 1.22.2 patch release.
publishdate: 2024-06-27
release: 1.22.2
---

This release implements the security updates described in our 27th of June post, [`ISTIO-SECURITY-2024-005`](/news/security/istio-security-2024-005) along with bug fixes to improve robustness.

This release note describes what is different between Istio 1.22.1 and 1.22.2.

{{< relnote >}}

## Changes

- **Improved** waypoint proxies to no longer run as root.

- **Added** `gateways.securityContext` to manifests to provide an option to customize the gateway `securityContext`.
  ([Issue #49549](https://github.com/istio/istio/issues/49549))

- **Added** a new option in ztunnel to completely disable IPv6, to enable running on kernels with IPv6 disabled.

- **Fixed** an issue where `istioctl analyze` returned IST0162 false positives.
  ([Issue #51257](https://github.com/istio/istio/issues/51257))

- **Fixed** `ENABLE_ENHANCED_RESOURCE_SCOPING` not being part of helm compatibility profiles for Istio 1.20/1.21.
  ([Issue #51399](https://github.com/istio/istio/issues/51399))

- **Fixed** Kubernetes job pod IPs may not be fully unenrolled from ambient despite being in a terminated state.

- **Fixed** false positives in IST0128 and IST0129 when `credentialName` and `workloadSelector` were set.
  ([Issue #51567](https://github.com/istio/istio/issues/51567))

- **Fixed** an issue where JWKS fetched from URIs were not updated promptly when there are errors fetching other URIs.
  ([Issue #51636](https://github.com/istio/istio/issues/51636))

- **Fixed** an issue causing `workloadSelector` policies to apply to the wrong namespace in ztunnel.
  ([Issue #51556](https://github.com/istio/istio/issues/51556))

- **Fixed** a bug causing `discoverySelectors` to accidentally filter out all `GatewayClasses`.

- **Fixed** certificate chains parsing avoid unnecessary parsing errors by trimming unnecessary intermediate certificates.

- **Fixed** a bug in ambient mode causing requests at the start of a Pod lifetime to be rejected with `unknown source`.

- **Fixed** an issue in ztunnel where some expected connection terminations were reported as errors.

- **Fixed** an issue in ztunnel when connecting to a service with a `targetPort` that exists only on a subset of pods.

- **Fixed** an issue when deleting a `ServiceEntry` when there are duplicate hostnames across multiple `ServiceEntries`.

- **Fixed** an issue where ztunnel would send directly to pods when connecting to a `LoadBalancer` IP, instead of going through the `LoadBalancer`.

- **Fixed** an issue where ztunnel would send traffic to terminating pods.

---
title: Announcing Istio 1.21.4
linktitle: 1.21.4
subtitle: Patch Release
description: Istio 1.21.4 patch release.
publishdate: 2024-06-27
release: 1.21.4
---

This release implements the security updates described in our 27th of June post, [`ISTIO-SECURITY-2024-005`](/news/security/istio-security-2024-005) along with bug fixes to improve robustness.

This release note describes what is different between Istio 1.21.3 and 1.21.4.

{{< relnote >}}

## Changes

- **Added** `gateways.securityContext` to manifests to provide an option to customize the gateway `securityContext`.
  ([Issue #49549](https://github.com/istio/istio/issues/49549))

- **Fixed** an issue where `istioctl analyze` returned IST0162 false positives.
  ([Issue #51257](https://github.com/istio/istio/issues/51257))

- **Fixed** false positives in IST0128 and IST0129 when `credentialName` and `workloadSelector` were set.
  ([Issue #51567](https://github.com/istio/istio/issues/51567))

- **Fixed** an issue where JWKS fetched from URIs were not updated promptly when there are errors fetching other URIs.
  ([Issue #51636](https://github.com/istio/istio/issues/51636))

- **Fixed** 503 errors returned by `auto-passthrough` gateways created after enabling mTLS.

- **Fixed** `serviceRegistry` ordering of the proxy labels, so we put the Kubernetes registry in front.
  ([Issue #50968](https://github.com/istio/istio/issues/50968))

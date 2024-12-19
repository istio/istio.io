---
title: Announcing Istio 1.24.2
linktitle: 1.24.2
subtitle: Patch Release
description: Istio 1.24.2 patch release.
publishdate: 2024-12-18
release: 1.24.2
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.24.1 and Istio 1.24.2.

This release implements the security updates described in our 18th of December post, [`ISTIO-SECURITY-2024-007`](/news/security/istio-security-2024-007).

{{< relnote >}}

## Changes

- **Added** the `DAC_OVERRIDE` capability to the `istio-cni-node` DaemonSet. This fixes issues when running in environments
  where certain files are owned by non-root users.
  Note: prior to Istio 1.24, the `istio-cni-node` ran as `privileged`. Istio 1.24 removed this, but removed some required
  privileges which are now added back. Relatively to Istio 1.23, `istio-cni-node` still has fewer privileges than it does
  with this change.

- **Fixed** Helm rendering to properly apply annotations on Pilot's `ServiceAccount`.
  ([Issue #51289](https://github.com/istio/istio/issues/51289))

- **Fixed** an issue where `istiod` did not handle `RequestAuthentication` correctly for cross-namespace waypoint proxies.
  ([Issue #54051](https://github.com/istio/istio/issues/54051))

- **Fixed** an issue where non-default revisions controlled gateways lacked `istio.io/rev` labels.
  ([Issue #54280](https://github.com/istio/istio/issues/54280))

- **Fixed** an issue where `ExternalName` services failed to resolve when using ambient mode and DNS proxying.

- **Fixed** an issue preventing the `PodDisruptionBudget` `maxUnavailable` field from being configured.
  ([Issue #54087](https://github.com/istio/istio/issues/54087))

- **Fixed** an issue where injection config errors were being silenced (i.e. logged and not returned) when the sidecar injector was unable to process the sidecar config. This change will now propagate the error to the user instead of continuing to process a faulty config.  ([Issue #53357](https://github.com/istio/istio/issues/53357))

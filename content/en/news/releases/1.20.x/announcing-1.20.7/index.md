---
title: Announcing Istio 1.20.7
linktitle: 1.20.7
subtitle: Patch Release
description: Istio 1.20.7 patch release.
publishdate: 2024-06-04
release: 1.20.7
---

This release implements the security updates described in our 4th of June post, [`ISTIO-SECURITY-2024-004`](/news/security/istio-security-2024-004) along with bug fixes to improve robustness.

This release note describes what’s different between Istio 1.20.6 and 1.20.7.

{{< relnote >}}

## Changes

- **Fixed** building of EDS-typed cluster endpoints with domain address.
  ([Issue #50688](https://github.com/istio/istio/issues/50688))

- **Fixed** custom injection of the `istio-proxy` container not working properly when `SecurityContext.RunAs` fields were set.

- **Fixed** a regression in Istio 1.21.0 causing `VirtualService`s routing to `ExternalName` services to not work when
  `ENABLE_EXTERNAL_NAME_ALIAS=false` was configured.

- **Fixed** a behavioral change in Istio 1.20 that caused merging of `ServiceEntries` with the same hostname and port names
  to give unexpected results.
  ([Issue #50478](https://github.com/istio/istio/issues/50478))

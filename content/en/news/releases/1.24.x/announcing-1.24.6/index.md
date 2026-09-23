---
title: Announcing Istio 1.24.6
linktitle: 1.24.6
subtitle: Patch Release
description: Istio 1.24.6 patch release.
publishdate: 2025-05-13
release: 1.24.6
---


This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.24.5 and Istio 1.24.6.

{{< relnote >}}

## Security Updates

- [CVE-2025-46821](https://nvd.nist.gov/vuln/detail/CVE-2025-46821) (CVSS Score 5.3, Medium): Bypass of RBAC `uri_template` permission.

If you use `**` within an `AuthorizationPolicy`'s path field, it is recommended you upgrade to Istio 1.24.6.

## Changes

- **Fixed** an issue where validation webhook incorrectly reported a warning when a `ServiceEntry` configured `workloadSelector` with DNS resolution.
  ([Issue #50164](https://github.com/istio/istio/issues/50164))

- **Removed** the restriction where revision tag only worked when `istiodRemote` was not enabled in the istiod helm chart. Revision tags now work as long as the `revisionTags` is specified without regard to whether `istiodRemote` is enabled or not.
  ([Issue #54743](https://github.com/istio/istio/issues/54743))

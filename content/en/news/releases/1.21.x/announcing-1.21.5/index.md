---
title: Announcing Istio 1.21.5
linktitle: 1.21.5
subtitle: Patch Release
description: Istio 1.21.5 patch release.
publishdate: 2024-07-16
release: 1.21.5
---

This release note describes what is different between Istio 1.21.4 and 1.21.5.

{{< relnote >}}

## Changes

- **Updated** Go version to include security fixes for the net/http package related to [`CVE-2024-24791`](https://nvd.nist.gov/vuln/detail/CVE-2024-24791)

- **Updated** Envoy version to include security fixes related to [`CVE-2024-39305`](https://github.com/envoyproxy/envoy/security/advisories/GHSA-fp35-g349-h66f)

- **Fixed** a bug where router's merged gateway was not immediately recomputed when a service was created or updated.
  ([Issue #51726](https://github.com/istio/istio/issues/51726))

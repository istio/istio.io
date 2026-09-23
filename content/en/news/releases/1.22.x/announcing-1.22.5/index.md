---
title: Announcing Istio 1.22.5
linktitle: 1.22.5
subtitle: Patch Release
description: Istio 1.22.5 patch release.
publishdate: 2024-09-19
release: 1.22.5
---

This release fixes the security vulnerabilities described in our September 19th post, [ISTIO-SECURITY-2024-006](/news/security/istio-security-2024-006).
This release note describes what’s different between Istio 1.22.4 and 1.22.5.

{{< relnote >}}

## Changes

- **Fixed** `PILOT_SIDECAR_USE_REMOTE_ADDRESS` functionality on sidecars to support setting internal addresses to mesh network rather than localhost to prevent header sanitization if `envoy.reloadable_features.explicit_internal_address_config` is enabled.

- **Removed** a change in 1.22.4 to the handling of multiple service VIPs in ServiceEntry.
  ([Issue #52944](https://github.com/istio/istio/issues/52944)), ([Issue #52847](https://github.com/istio/istio/issues/52847))

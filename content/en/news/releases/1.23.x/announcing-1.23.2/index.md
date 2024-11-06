---
title: Announcing Istio 1.23.2
linktitle: 1.23.2
subtitle: Patch Release
description: Istio 1.23.2 patch release.
publishdate: 2024-09-19
release: 1.23.2
---

This release fixes the security vulnerabilities described in our September 19th post, [ISTIO-SECURITY-2024-006](/news/security/istio-security-2024-006).
This release note describes what’s different between Istio 1.23.1 and 1.23.2.

{{< relnote >}}

## Changes

- **Fixed** `PILOT_SIDECAR_USE_REMOTE_ADDRESS` functionality on sidecars to support setting internal addresses to mesh network rather than localhost to prevent header sanitization if `envoy.reloadable_features.explicit_internal_address_config` is enabled.

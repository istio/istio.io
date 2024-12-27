---
title: Announcing Istio 1.21.6
linktitle: 1.21.6
subtitle: Patch Release
description: Istio 1.21.6 patch release.
publishdate: 2024-09-23
release: 1.21.6
---

This release fixes the security vulnerabilities described in our September 19th post, [ISTIO-SECURITY-2024-006](/news/security/istio-security-2024-006).
This release note describes what’s different between Istio 1.21.5 and 1.21.6.

{{< relnote >}}

## Changes

- **Fixed** `PILOT_SIDECAR_USE_REMOTE_ADDRESS` functionality on sidecars to support setting internal addresses to mesh network rather than localhost to prevent header sanitization if `envoy.reloadable_features.explicit_internal_address_config` is enabled.

- **Fixed** `VirtualMachine` `WorkloadEntry` locality label missing during auto registration.
  ([Issue #51800](https://github.com/istio/istio/issues/51800))

---
title: Announcing Istio 1.19.9
linktitle: 1.19.9
subtitle: Patch Release
description: Istio 1.19.9 patch release.
publishdate: 2024-04-08
release: 1.19.9
---

This release implements the security updates described in our 8th of April post, [`ISTIO-SECURITY-2024-002`](/news/security/istio-security-2024-002) along with bug fixes to improve robustness.

This release note describes what’s different between Istio 1.19.8 and 1.19.9.

{{< relnote >}}

## Changes

- **Fixed** an issue where updating a `ServiceEntry`'s `TargetPort` would not trigger an xDS push.
  ([Issue #49878](https://github.com/istio/istio/issues/49878))

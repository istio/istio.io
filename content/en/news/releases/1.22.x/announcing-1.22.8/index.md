---
title: Announcing Istio 1.22.8
linktitle: 1.22.8
subtitle: Patch Release
description: Istio 1.22.8 patch release.
publishdate: 2025-01-22
release: 1.22.8
---

This release note describes what’s different between Istio 1.22.7 and 1.22.8.

{{< relnote >}}

## Changes

- **Fixed** an issue where Ambient `PeerAuthentication` policies were overly strict.
  ([Issue #53884](https://github.com/istio/istio/issues/53884))

- **Fixed** a bug in Ambient (only) where multiple STRICT port-level mTLS rules in a PeerAuthentication policy would effectively result in a permissive policy due to incorrect evaluation logic (AND vs. OR).
  ([Issue #54146](https://github.com/istio/istio/issues/54146))

- **Fixed** an issue that access log order instability causing connection draining.
  ([Issue #54672](https://github.com/istio/istio/issues/54672))

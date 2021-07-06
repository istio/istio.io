---
title: Announcing Istio 1.10.1
linktitle: 1.10.1
subtitle: Patch Release
description: Istio 1.10.1 patch release.
publishdate: 2021-06-09
release: 1.10.1
aliases:
    - /news/announcing-1.10.1
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.10.0 and Istio 1.10.1.

{{< relnote >}}

## Changes

- **Fixed** an issue causing the `Host` header to not be modifiable for specific destinations in a `VirtualService` ([Issue #33226](https://github.com/istio/istio/issues/33226))

- **Fixed** an issue that made it impossible to set the PDB `maxUnavailable` field in `IstioOperator` ([Issue #31910](https://github.com/istio/istio/issues/31910))

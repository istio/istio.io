---
title: Announcing Istio 1.7.7
linktitle: 1.7.7
subtitle: Patch Release
description: Istio 1.7.7 patch release.
publishdate: 2021-01-29
release: 1.7.7
aliases:
- /news/announcing-1.7.7
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.7.6 and Istio 1.7.7

{{< relnote >}}

## Changes

- **Fixed** an issue of using explicitly empty revision flag on install.
  ([Issue #26940](https://github.com/istio/istio/issues/26940))
- **Fixed** the CA’s certificate signature algorithm to be the default algorithm corresponding to the CA’s signing key type.
  ([Issue #27238](https://github.com/istio/istio/issues/27238))
- **Fixed** an issue showing unnecessary warnings when downgrading to a lower version of Istio.
  ([Issue #29183](https://github.com/istio/istio/issues/29183))
- **Fixed** an issue causing older control planes relying on the `rbac.istio.io` CRD group to hang on restart due to the fact that newer control plane installations remove those permissions from istiod.
  ([Issue #29364](https://github.com/istio/istio/issues/29364))
- **Fixed** a memory leak in WASM `NullPlugin` `onNetworkNewConnection`.
  ([Issue #24720](https://github.com/istio/istio/issues/24720))

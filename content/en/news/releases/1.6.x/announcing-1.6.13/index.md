---
title: Announcing Istio 1.6.13
linktitle: 1.6.13
subtitle: Patch Release
description: Istio 1.6.13 patch release.
publishdate: 2020-10-23
release: 1.6.13
aliases:
    - /news/announcing-1.6.13
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.6.12 and Istio 1.6.13

{{< relnote >}}

# Changes

- **Fixed** an issue that Istiod's cacert.pem is under testdata directory
  ([Issue #27574](https://github.com/istio/istio/issues/27574))

- **Fixed** pilot agent app probe connection leak.
  ([Issue #27726](https://github.com/istio/istio/issues/27726))


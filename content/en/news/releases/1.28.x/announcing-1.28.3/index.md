---
title: Announcing Istio 1.28.3
linktitle: 1.28.3
subtitle: Patch Release
description: Istio 1.28.3 patch release.
publishdate: 2026-01-19
release: 1.28.3
aliases:
    - /news/announcing-1.28.3
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.28.2 and 1.28.3.

{{< relnote >}}

## Changes

- **Added** `service.selectorLabels` field to gateway Helm chart for custom service selector labels during revision-based migrations.

- **Fixed** an issue with goroutine memory leaks in ambient mode.
  ([Issue #58478](https://github.com/istio/istio/issues/58478))

- **Fixed** an issue in ambient multicluster where informer failures for remote clusters wouldn't be fixed until an istiod restart.
  ([Issue #58047](https://github.com/istio/istio/issues/58047))

- **Fixed** an issue with crashing NFT operations and pod deletion failures.
  ([Issue #58492](https://github.com/istio/istio/issues/58492))

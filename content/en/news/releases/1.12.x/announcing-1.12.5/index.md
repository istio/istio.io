---
title: Announcing Istio 1.12.5
linktitle: 1.12.5
subtitle: Patch Release
description: Istio 1.12.5 patch release.
publishdate: 2022-03-08
release: 1.12.5
aliases:
    - /news/announcing-1.12.5
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.12.4 and Istio 1.12.5.

{{< relnote >}}

## Changes

- **Fixed** an issue with Delta CDS where a removed service port would persist after being updated.
  ([Pull Request #37454](https://github.com/istio/istio/pull/37454))

- **Fixed** an issue where CNI ignored traffic annotations.
  ([Issue #37637](https://github.com/istio/istio/issues/37637))

- **Fixed** a bug where cache entries were never updated.
  ([Pull Request #37578](https://github.com/istio/istio/pull/37578))

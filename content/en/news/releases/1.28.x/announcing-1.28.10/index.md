---
title: Announcing Istio 1.28.10
linktitle: 1.28.10
subtitle: Patch Release
description: Istio 1.28.10 patch release.
publishdate: 2026-06-30
release: 1.28.10
aliases:
    - /news/announcing-1.28.10
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.28.9 and 1.28.10.

{{< relnote >}}

## Changes

- **Fixed** a memory leak in the `krt` controller framework where changing the key used in a `Fetch` filter
  (for example, relabeling a pod to point to a different waypoint) left stale reverse-index entries that were 
  never cleaned up. Over time this could grow memory usage and cause unnecessary recomputations.


---
title: Announcing Istio 1.21.2
linktitle: 1.21.2
subtitle: Patch Release
description: Istio 1.21.2 patch release.
publishdate: 2024-04-22
release: 1.21.2
---

This release implements the security updates described in our 22nd of April post, [`ISTIO-SECURITY-2024-003`](/news/security/istio-security-2024-003) along with bug fixes to improve robustness.

This release note describes what’s different between Istio 1.21.1 and 1.21.2.

{{< relnote >}}

## Changes

- **Added** `pprof` endpoints to profile the CNI pod (on port 9867).
  ([Issue #49053](https://github.com/istio/istio/issues/49053))

- **Improved** CNI memory usage by avoiding keeping large files in memory.
  ([Issue #49053](https://github.com/istio/istio/issues/49053))

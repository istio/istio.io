---
title: Announcing Istio 1.29.1
linktitle: 1.29.1
subtitle: Patch Release
description: Istio 1.29.1 patch release.
publishdate: 2026-02-20
release: 1.29.1
aliases:
    - /news/announcing-1.29.1
---

This release contains bug fixes to improve robustness. This release note describes what's different between Istio 1.29.0 and 1.29.1.

{{< relnote >}}

## Changes

- **Fixed** potential SSRF in WasmPlugin image fetching by validating bearer token realm URLs.

Special thanks to Sergey KANIBOR at Luntry for reporting the WasmPlugin image fetching issue.

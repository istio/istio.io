---
title: Announcing Istio 1.6.14
linktitle: 1.6.14
subtitle: Patch Release
description: Istio 1.6.14 patch release.
publishdate: 2020-11-23
release: 1.6.14
aliases:
    - /news/announcing-1.6.14
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.6.13 and Istio 1.6.14

{{< relnote >}}

## Changes

- **Fixed** HPA settings for telemetry being overridden by the inline replicas.
  ([Issue #28916](https://github.com/istio/istio/issues/28916))
- **Fixed** an issue that caused very high memory usage with a large number of `ServiceEntries`.
  ([Issue #25531](https://github.com/istio/istio/issues/25531))
- **Fixed** an issue that caused the `user agent` header to be missing in the Stackdriver access log.
  ([PR #3083](https://github.com/istio/proxy/pull/3083))

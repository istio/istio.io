---
title: Announcing Istio 1.5.10
linktitle: 1.5.10
subtitle: Patch Release
description: Istio 1.5.10 patch release.
publishdate: 2020-08-24
release: 1.5.10
aliases:
    - /news/announcing-1.5.10
---

This release includes bug fixes to improve robustness. These release notes describe what's different between Istio 1.5.9 and Istio 1.5.10.

{{< relnote >}}

## Bug fixes

- **Fixed** container name as `app_container` in telemetry v2.
- **Fixed** ingress SDS not getting secret updates. ([Issue 23715](https://github.com/istio/istio/issues/23715)).

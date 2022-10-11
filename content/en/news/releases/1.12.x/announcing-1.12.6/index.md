---
title: Announcing Istio 1.12.6
linktitle: 1.12.6
subtitle: Patch Release
description: Istio 1.12.6 patch release.
publishdate: 2022-04-06
release: 1.12.6
aliases:
    - /news/announcing-1.12.6
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.12.5 and Istio 1.12.6

{{< relnote >}}

## Changes

- **Fixed** an issue where executing `istioctl upgrade` on 1.12 would result in webhook overlap errors.
  ([Issue #37908](https://github.com/istio/istio/issues/37908))

- **Fixed** an issue that caused TCP calls to still be logged after disabling the access logging through the Telemetry API.

- **Fixed** an issue causing some cross-namespace `VirtualServices` to be incorrectly ignored after upgrading to Istio 1.12+.
  ([Issue #37691](https://github.com/istio/istio/issues/37691))

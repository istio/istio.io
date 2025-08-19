---
title: Announcing Istio 1.10.6
linktitle: 1.10.6
subtitle: Patch Release
description: Istio 1.10.6 patch release.
publishdate: 2021-11-29
release: 1.10.6
aliases:
    - /news/announcing-1.10.6
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.10.5 and Istio 1.10.6.

{{< relnote >}}

## Changes

- **Fixed** an issue that prevented the in-cluster operator from pruning resources when the Istio control plane had active proxies connected.
  ([Issue #35657](https://github.com/istio/istio/issues/35657))

- **Fixed** an issue causing workload name metric labels to be incorrectly populated for `CronJob`s for k8s 1.21+.
  ([Issue #35563](https://github.com/istio/istio/issues/35563))

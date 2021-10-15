---
title: Announcing Istio 1.11.4
linktitle: 1.11.4
subtitle: Patch Release
description: Istio 1.11.4 patch release.
publishdate: 2021-10-14
release: 1.11.4
aliases:
    - /news/announcing-1.11.4
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.11.3 and Istio 1.11.4

{{< relnote >}}

## Changes

- **Fixed** VMs are able to use a revisioned control plane specified by `--revision` on the `istioctl x workload entry`
command.

- **Fixed** an issue when creating a Service and Gateway at the same time, causing the Service to be ignored.
  ([Issue #35172](https://github.com/istio/istio/issues/35172))

- **Fixed** an issue causing stale endpoints for service entry selecting pods
  ([Issue #35404](https://github.com/istio/istio/issues/35404))

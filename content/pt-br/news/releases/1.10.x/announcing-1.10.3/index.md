---
title: Announcing Istio 1.10.3
linktitle: 1.10.3
subtitle: Patch Release
description: Istio 1.10.3 patch release.
publishdate: 2021-07-16
release: 1.10.3
aliases:
    - /news/announcing-1.10.3
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.10.2 and Istio 1.10.3.

{{< relnote >}}

## Changes

- **Fixed** a bug where wildcard hosts were incorrectly added even when a `Sidecar` resource only specified particular hosts.  ([Issue #33387](https://github.com/istio/istio/issues/33387))

- **Fixed** a bug where setting the `retryRemoteLocalities` on a `VirtualService` would produce configuration that Envoy would reject.  ([Issue #33737](https://github.com/istio/istio/issues/33737))

- **Improved** the `meshConfig.defaultConfig.proxyMetadata` field to do a deep merge when overridden rather than replacing all values.

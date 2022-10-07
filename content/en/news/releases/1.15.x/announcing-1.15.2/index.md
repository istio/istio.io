---
title: Announcing Istio 1.15.2
linktitle: 1.15.2
subtitle: Patch Release
description: Istio 1.15.2 patch release.
publishdate: 2022-10-07
release: 1.15.2
---

This release includes security fixes in Go 1.19.2 (released 2022-10-04) for the `archive/tar`, `net/http/httputil`, and `regexp` packages.
This release contains bug fixes to improve robustness.
This release note describes what is different between Istio 1.15.2 and Istio 1.15.2.

{{< relnote >}}

## Changes

- **Fixed** an issue that the default `idleTimeout` for the passthrough cluster was changed to `0s` in 1.14.0, disabling the timeout. Restored the previous behavior to using Envoy's default value of 1 hour. ([Issue #41114](https://github.com/istio/istio/issues/41114))

- **Fixed** the gateway API integration to not fail when the v1alpha2 version is removed.

- **Fixed** handling of deprecated autoscaling settings. ([Issue #41011](https://github.com/istio/istio/issues/41011))

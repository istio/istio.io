---
title: Announcing Istio 1.15.1
linktitle: 1.15.1
subtitle: Patch Release
description: Istio 1.15.1 patch release.
publishdate: 2022-09-26
release: 1.15.1
---

This release includes security fixes in Go 1.19.2 (released 2022-10-04) for the `archive/tar`, `net/http/httputil`, and `regexp` packages.

This release contains bug fixes to improve robustness.

This release note describes what is different between Istio 1.15.1 and Istio 1.15.2.

{{< relnote >}}

## Changes

- **Fixed** an issue that default `idleTimeout` for passthrough cluster has been changed to `0s` since 1.14.0 and timeout is disabled. Previous behavior is using envoy's default value. ([Issue #41114](https://github.com/istio/istio/issues/41114))

- **Fixed** the gateway-api integration to read `v1beta1` resources for `HTTPRoute`, `Gateway`, and `GatewayClass`. Users of the gateway-api must be on v0.5.0+ before upgrading Istio.

- **Fixed** handling of deprecated autoscaling settings. ([Issue #41011](https://github.com/istio/istio/issues/41011))

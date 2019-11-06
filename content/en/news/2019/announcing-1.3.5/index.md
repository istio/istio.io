---
title: Announcing Istio 1.3.5
description: Istio 1.3.5 release announcement.
publishdate: 2019-11-06
attribution: The Istio Team
subtitle: Minor Update
release: 1.3.5
aliases:
    - /news/announcing-1.3.5
---

This release includes bug fixes to improve robustness. This release note describes what's different between Istio 1.3.4 and Istio 1.3.5.

{{< relnote >}}

## Bug fixes

- **Fixed** Envoy listener configuration for TCP headless services. ([Issue #17748](https://github.com/istio/istio/issues/17748))
- **Fixed** an issue which caused stale endpoints to remain even when a deployment was scaled to 0 replicas. ([Issue #14436](https://github.com/istio/istio/issues/14336))
- **Fixed** Pilot to gracefully handle generating invalid Envoy configuration. ([Issue 17266](https://github.com/istio/istio/issues/17266))

## Minor enhancements

- **Added** support for Citadel to periodically check the root certificate remaining lifetime and rotate expiring root certificates. ([Issue 17059](https://github.com/istio/istio/issues/17059))
- **Added** `PILOT_BLOCK_HTTP_ON_443` environment variable. If enabled, this flag will prevent HTTP services from running on port 443 in order to prevent conflicts with external HTTP services. This is disabled by default, but will be enabled in 1.4. ([Issue 16458](https://github.com/istio/istio/issues/16458))
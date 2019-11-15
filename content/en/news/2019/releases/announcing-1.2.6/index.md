---
title: Announcing Istio 1.2.6
subtitle: Patch Release
description: Istio 1.2.6 patch release.
publishdate: 2019-09-17
release: 1.2.6
aliases:
    - /about/notes/1.2.6
    - /blog/2019/announcing-1.2.6
    - /news/announcing-1.2.6
---

We're pleased to announce the availability of Istio 1.2.6. Please see below for what's changed.

{{< relnote >}}

## Bug fixes

- Fix `redisquota` inconsistency in regards to `memquota` counting ([Issue 15543](https://github.com/istio/istio/issues/15543)).
- Fix an Envoy crash introduced in Istio 1.2.5 ([Issue 16357](https://github.com/istio/istio/issues/16357)).
- Fix Citadel health check broken in the context of plugin certs (with intermediate certs) ([Issue 16593](https://github.com/istio/istio/issues/16593)).
- Fix Stackdriver Mixer Adapter error log verbosity ([Issue 16782](https://github.com/istio/istio/issues/16782)).
- Fix a bug where the service account map would be erased for service hostnames with more than one port.
- Fix incorrect `filterChainMatch` wildcard hosts duplication produced by Pilot ([Issue 16573](https://github.com/istio/istio/issues/16573)).

## Small enhancements

- Expose `sidecarToTelemetrySessionAffinity` (required for Mixer V1) when it talks to services like Stackdriver. ([Issue 16862](https://github.com/istio/istio/issues/16862)).
- Expose `HTTP/2` window size settings as Pilot environment variables ([Issue 17117](https://github.com/istio/istio/issues/17117)).

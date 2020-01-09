---
title: Announcing Istio 1.0.4
linktitle: 1.0.4
subtitle: Patch Release
description: Istio 1.0.4 patch release.
publishdate: 2018-11-21
release: 1.0.4
aliases:
    - /about/notes/1.0.4
    - /blog/2018/announcing-1.0.4
    - /news/2018/announcing-1.0.4
    - /news/announcing-1.0.4
---

We're pleased to announce the availability of Istio 1.0.4. Please see below for what's changed.

{{< relnote >}}

## Known issues

- Pilot may deadlock when using [`istioctl proxy-status`](/pt-br/docs/reference/commands/istioctl/#istioctl-proxy-status) to get proxy synchronization status.
  The work around is to *not use* `istioctl proxy-status`.
  Once Pilot enters a deadlock, it exhibits continuous memory growth eventually running out of memory.

## Networking

- Fixed the lack of removal of stale endpoints causing `503` errors.

- Fixed sidecar injection when a pod label contains a `/`.

## Policy and telemetry

- Fixed occasional data corruption problem with out-of-process Mixer adapters leading to incorrect behavior.

- Fixed excessive CPU usage by Mixer when waiting for missing CRDs.

---
title: Istio 1.0.4
publishdate: 2018-11-21
icon: notes
---

This release addresses some critical issues found by the community when using Istio 1.0.3.
This release note describes what's different between Istio 1.0.3 and Istio 1.0.4.

{{< relnote_links >}}

## Known issues

- Pilot may deadlock when using [`istioctl proxy-status`](/docs/reference/commands/istioctl/#istioctl-proxy-status) to get proxy synchronization status.
  The work around is to *not use* `istioctl proxy-status`.
  Once Pilot enters a deadlock, it exhibits continuous goroutine growth eventually running out of memory.

## Networking

- Fixed the lack of removal of stale endpoints causing `503` errors.

- Fixed sidecar injection when a pod label contains a `/`.

## Policy and telemetry

- Fixed occasional data corruption problem with out-of-process Mixer adapters leading to incorrect behavior.

- Fixed excessive CPU usage by Mixer when waiting for missing CRDs.

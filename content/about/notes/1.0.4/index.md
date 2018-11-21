---
title: Istio 1.0.4
weight: 88
icon: notes
---

This release addresses some critical issues found by the community when using Istio 1.0.3.
This release note describes what's different between Istio 1.0.3 and Istio 1.0.4.

{{< relnote_links >}}

## Networking

- Fixed the lack of removal of stale endpoints causing `503` errors.

- Fixed sidecar injection when a pod label contains a `/`.

## Policy and telemetry

- Fixed serialized configuration corruption due to buffer re-use for OOP Mixer adapters.

- Fixed excessive CPU usage by Mixer when waiting for missing CRDs.

---
title: Announcing Istio 1.13.2
linktitle: 1.13.2
subtitle: Patch Release
description: Istio 1.13.2 patch release.
publishdate: 2022-03-09
release: 1.13.2
aliases:
    - /news/announcing-1.13.2
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.13.1 and Istio 1.13.2

{{< relnote >}}

## Changes

- **Added** OpenTelemetry Access Log.
  
- **Added** support for using default JSON access logs format with Telemetry API.
  ([Issue #37663](https://github.com/istio/istio/issues/37663))

- **Fixed** `describe pod` not showing the VirtualService info if the gateway is set to TLS ingress gateway.
  ([Issue #35301](https://github.com/istio/istio/issues/35301))

- **Fixed** an issue where `traffic.sidecar.istio.io/includeOutboundPorts` annotation does not take effect when using CNI.
  ([Issue #37637](https://github.com/istio/istio/pull/37637))

- **Fixed** an issue where when enabling Stackdriver metrics collection with the Telemetry API, logging was incorrectly enabled in certain scenarios.
  ([Issue #37667](https://github.com/istio/istio/issues/37667))

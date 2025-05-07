---
title: Announcing Istio 1.25.1
linktitle: 1.25.1
subtitle: Patch Release
description: Istio 1.25.1 patch release.
publishdate: 2025-03-26
release: 1.25.1
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.25.0 and Istio 1.25.1.

{{< relnote >}}

## Security Update

- [CVE-2025-30157](https://nvd.nist.gov/vuln/detail/CVE-2025-30157) (CVSS Score 6.5, Medium): Envoy crashes when HTTP `ext_proc` processes local replies.

For the purposes of Istio, this CVE is only exploitable in circumstances where `ext_proc` is configured via `EnvoyFilter`.

## Changes

- **Added** status information to `HTTPRoute` resources to indicate the status of `parentRefs` for service and service entry resources,
  as well as a new condition to indicate the status of waypoint configuration when in ambient mode.

- **Fixed** validation webhook rejecting an otherwise valid `connectionPool.tcp.IdleTimeout=0s` configuration.
  ([Issue #55409](https://github.com/istio/istio/issues/55409))

- **Fixed** an issue where validation webhook incorrectly reported a warning when a `ServiceEntry` configured `workloadSelector` with DNS resolution.
  ([Issue #50164](https://github.com/istio/istio/issues/50164))

- **Fixed** an issue where `HTTPRoute` status was not reporting a `parentRef` associated with a single result
  due to complex logic for collapsing `parentRefs` of the same reference, but different `sectionNames`.

- **Fixed** `IstioCertificateService` to ensure `IstioCertificateResponse.CertChain` contained only a single certificate per element in the array.
  ([Issue #1061](https://github.com/istio/ztunnel/issues/1061))

- **Fixed** an issue causing waypoints to downgrade HTTP2 traffic to HTTP/1.1 if the port was not explicitly declared as `http2`.

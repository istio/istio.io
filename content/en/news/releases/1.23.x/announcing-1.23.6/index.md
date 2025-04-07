---
title: Announcing Istio 1.23.6
linktitle: 1.23.6
subtitle: Patch Release
description: Istio 1.23.6 patch release.
publishdate: 2025-04-07
release: 1.23.6
aliases:
    - /news/announcing-1.23.6
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.23.5 and Istio 1.23.6.
{{< relnote >}}

## Security Updates

- [CVE-2025-30157](https://nvd.nist.gov/vuln/detail/CVE-2025-30157) (CVSS Score 6.5, Medium): Envoy crashes when HTTP `ext_proc` processes local replies.

For the purposes of Istio, this CVE is only exploitable in circumstances where `ext_proc` is configured via `EnvoyFilter`.

## Changes

- **Fixed** an issue where customizing the workload identity SDS socket name
  via `WORKLOAD_IDENTITY_SOCKET_FILE` did not work due to the Envoy bootstrap not being updated.
  ([Issue #51979](https://github.com/istio/istio/issues/51979))

- **Fixed** an issue where Istiod fails with an LDS error for proxies <1.23 when `meshConfig.accessLogEncoding` is set to `JSON`.
  ([Issue #55116](https://github.com/istio/istio/issues/55116))

- **Fixed** an issue where `gateway` injection template did not respect the `kubectl.kubernetes.io/default-logs-container`
  and `kubectl.kubernetes.io/default-container` annotations.

- **Fixed** an issue where validation webhook would reject an otherwise valid `connectionPool.tcp.IdleTimeout=0s`.
  ([Issue #55409](https://github.com/istio/istio/issues/55409))

- **Fixed** an issue where the validation webhook incorrectly reported a warning when a `ServiceEntry` configured `workloadSelector` with DNS resolution.
  ([Issue #50164](https://github.com/istio/istio/issues/50164))

- **Fixed** an issue where ingress gateways did not use WDS discovery to retrieve metadata for ambient destinations.

- **Fixed** DNS traffic (UDP and TCP) to now be affected by traffic annotations like `traffic.sidecar.istio.io/excludeOutboundIPRanges` and `traffic.sidecar.istio.io/excludeOutboundPorts`. Before, UDP/DNS traffic would uniquely ignore these traffic annotations, even if a DNS port was specified, because of the rule structure. The behavior change actually happened in the 1.23 release series, but was left out of the release notes for 1.23.
  ([Issue #53949](https://github.com/istio/istio/issues/53949))

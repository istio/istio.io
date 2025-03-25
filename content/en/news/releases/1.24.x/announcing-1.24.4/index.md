---
title: Announcing Istio 1.24.4
linktitle: 1.24.4
subtitle: Patch Release
description: Istio 1.24.3 patch release.
publishdate: 2025-03-25
release: 1.24.4
---


This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.24.3 and Istio 1.24.4.

{{< relnote >}}

## Security Updates

- [CVE-2025-30157](https://nvd.nist.gov/vuln/detail/CVE-2025-30157) (CVSS Score 6.5, Medium): Envoy crashes when HTTP `ext_proc` processes local replies.

For the purposes of Istio, this CVE is only exploitable in circumstances where `ext_proc` is conflicted via `EnvoyFilter`.

## Changes

- **Fixed** a bug with mixed-case Hosts in Gateway and TLS redirect resulted in stale RDS.
  ([Issue #49638](https://github.com/istio/istio/issues/49638))

- **Fixed** an issue where Ambient `PeerAuthentication` policies were overly strict.
  ([Issue #53884](https://github.com/istio/istio/issues/53884))

- **Fixed** failure to patch managed gateway/waypoint deployments during upgrade to 1.24.
  ([Issue #54145](https://github.com/istio/istio/issues/54145))

- **Fixed** a bug in where multiple `STRICT` port-level mTLS rules in an ambient mode `PeerAuthentication` policy would effectively result
  in a permissive policy due to incorrect evaluation logic (AND vs. OR).
  ([Issue #54146](https://github.com/istio/istio/issues/54146))

- **Fixed** the wording of the status message when L7 rules are present in an AuthorizationPolicy which is bound to ztunnel, to be clearer.
  ([Issue #54334](https://github.com/istio/istio/issues/54334))

- **Fixed** a bug where the request mirror filter incorrectly computed the percentage.
  ([Issue #54357](https://github.com/istio/istio/issues/54357))

- **Fixed** an issue where using a tag in the `istio.io/rev` label on a gateway caused the gateway to be improperly programmed, and to lack status.
  ([Issue #54458](https://github.com/istio/istio/issues/54458))

- **Fixed** an issue where out-of-order ztunnel disconnects could put `istio-cni` in a state where it believes it has no connections.
  ([Issue #54544](https://github.com/istio/istio/issues/54544)),([Issue #53843](https://github.com/istio/istio/issues/53843))

- **Fixed** an issue where access log order caused instability during connection draining.
  ([Issue #54672](https://github.com/istio/istio/issues/54672))

- **Fixed** an issue in the gateway chart where `--set platform` worked but `--set global.platform` did not.

- **Fixed** an issue where ingress gateways did not use WDS discovery to retrieve metadata for ambient mode destinations.

- **Fixed** an issue causing the `istio-iptables` command to fail when a non-built-in table is present in the system.

- **Fixed** an issue causing configuration to be rejected when there is a partial overlap between IP addresses across multiple services.
  For example, a Service with `[IP-A]` and one with `[IP-B, IP-A]`.  ([Issue #52847](https://github.com/istio/istio/issues/52847))

- **Fixed** DNS traffic (UDP and TCP) is now affected by traffic annotations like `traffic.sidecar.istio.io/excludeOutboundIPRanges` and `traffic.sidecar.istio.io/excludeOutboundPorts`.
  Before, UDP/DNS traffic would uniquely ignore these traffic annotations, even if a DNS port was specified, because of the rule structure. The behavior change actually happened in the
  1.23 release series, but was left out of the release notes for 1.23.
  ([Issue #53949](https://github.com/istio/istio/issues/53949))

- **Fixed** validation webhook rejecting an otherwise valid configuration `connectionPool.tcp.IdleTimeout=0s`.
  ([Issue #55409](https://github.com/istio/istio/issues/55409))

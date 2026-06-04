---
title: Announcing Istio 1.29.4
linktitle: 1.29.4
subtitle: Patch Release
description: Istio 1.29.4 patch release.
publishdate: 2026-06-04
release: 1.29.4
aliases:
    - /news/announcing-1.29.4
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.29.3 and 1.29.4.

{{< relnote >}}

## Security Update

- [CVE-2026-47774](https://github.com/envoyproxy/envoy/security/advisories/GHSA-22m2-hvr2-xqc8) (CVSS score 7.5, High): An unauthenticated remote attacker can cause denial of service by exhausting memory in the Envoy process. Cookie header bytes are not fully accounted for during request header size validation, and HPACK header block limits are enforced on encoded bytes without a corresponding limit on total decoded header size, allowing attackers to trigger excessive memory consumption through specially crafted HTTP/2 requests.

## Changes

- **Added** an initialization check that verifies the bundled `nft` binary
  supports JSON output. The native nftables backend requires JSON to read
  configuration during pod removal. On hosts whose `nft` binary doesn't
  support JSON, those calls fail with `Error: JSON support not compiled-in` on
  every removal, and the CNI agent retries indefinitely. The new check detects
  this error at startup and falls back to the iptables backend.
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **Fixed** an issue where HTTPS listeners defined via `ListenerSet` failed to deliver TLS certificates when the parent Gateway used manual deployment.
  ([Issue #59535](https://github.com/istio/istio/issues/59535))

- **Fixed** an issue where HTTPRoute and GRPCRoute filters with invalid header values were silently dropped from the Envoy config instead of reporting an InvalidFilter status.
  ([Issue #59933](https://github.com/istio/istio/issues/59933))

- **Fixed** an issue where multi-network ambient did not route to the waypoint
  when the ingress on one network called a service on a different network, even
  when the Service was configured with `istio.io/ingress-use-waypoint`.

- **Fixed** a fatal `concurrent map writes` panic in the istio-cni agent when
two pods were added to the ambient mesh on the same node at the same time.
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **Fixed** an ambient mode bug where a single Service combining `publishNotReadyAddresses: true` with a `PreferSameZone` or `PreferSameNode` traffic distribution caused ztunnel to receive `healthPolicy: AllowAll` for every other Service using the same traffic-distribution preset, leading to traffic being routed to not-ready endpoints cluster-wide.
  ([Issue #60422](https://github.com/istio/istio/issues/60422))

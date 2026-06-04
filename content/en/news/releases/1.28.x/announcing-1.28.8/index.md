---
title: Announcing Istio 1.28.8
linktitle: 1.28.8
subtitle: Patch Release
description: Istio 1.28.8 patch release.
publishdate: 2026-06-04
release: 1.28.8
aliases:
    - /news/announcing-1.28.8
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.28.7 and 1.28.8.

{{< relnote >}}

## Security Update

- [CVE-2026-47774](https://github.com/envoyproxy/envoy/security/advisories/GHSA-22m2-hvr2-xqc8) (CVSS score 7.5, High): An unauthenticated remote attacker can cause denial of service by exhausting memory in the Envoy process. Cookie header bytes are not fully accounted for during request header size validation, and HPACK header block limits are enforced on encoded bytes without a corresponding limit on total decoded header size, allowing attackers to trigger excessive memory consumption through specially crafted HTTP/2 requests.

## Changes

- **Fixed** an issue where HTTPS listeners defined via `ListenerSet` failed to deliver TLS certificates when the parent `Gateway` used manual deployment.
  ([Issue #59535](https://github.com/istio/istio/issues/59535))

- **Fixed** an issue where `HTTPRoute` and `GRPCRoute` filters with invalid header values were silently dropped from the Envoy config instead of reporting an invalid filter status.
  ([Issue #59933](https://github.com/istio/istio/issues/59933))

- **Fixed** an ambient mode bug where a single `Service` combining `publishNotReadyAddresses: true` with a `PreferSameZone` or `PreferSameNode` traffic distribution caused ztunnel to receive `healthPolicy: AllowAll` for every other `Service` using the same traffic-distribution preset, leading to traffic being routed to not-ready endpoints cluster-wide.
  ([Issue #60422](https://github.com/istio/istio/issues/60422))

---
title: Announcing Istio 1.28.2
linktitle: 1.28.2
subtitle: Patch Release
description: Istio 1.28.2 patch release.
publishdate: 2025-12-22
release: 1.28.2
aliases:
    - /news/announcing-1.28.2
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.28.1 and 1.28.2.

{{< relnote >}}

## Security Update

- [CVE-2025-62408](https://github.com/envoyproxy/envoy/security/advisories/GHSA-fg9g-pvc4-776f) (CVSS score 5.3, Moderate): Use after free can crash Envoy due to malfunctioning or compromised DNS. This is a heap use-after-free vulnerability in the c-ares library that can be exploited by an attacker controlling the local DNS infrastructure to cause a Denial of Service (DoS) in Envoy.

## Changes

- **Fixed** rare race condition where deleting a `ServiceEntry` that shares a hostname with another `ServiceEntry` in the same namespace occasionally causes ambient clients to lose the ability to send traffic to that hostname until istiod restarts.

- **Fixed** use cases where upgrading from the iptables backend to the nftables backend in ambient created stale iptables rules on the network. The code now continues to use iptables on the node until it is rebooted. ([Issue #58353](https://github.com/istio/istio/issues/58353))

- **Fixed** DNS name table creation for headless services where pods entries did not account for pods to have multiple IPs.  ([Issue #58397](https://github.com/istio/istio/issues/58397))

- **Fixed** annotation `sidecar.istio.io/statsEvictionInterval` with values 60 seconds or more causing `istio-proxy` sidecar startup failure. ([Issue #58500](https://github.com/istio/istio/issues/58500))

- **Fixed** an issue where Envoy proxies that connect to waypoint proxies would in rare cases either get extraneous XDS updates or miss some updates entirely.

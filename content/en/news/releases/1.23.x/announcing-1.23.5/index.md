---
title: Announcing Istio 1.23.5
linktitle: 1.23.5
subtitle: Patch Release
description: Istio 1.23.5 patch release.
publishdate: 2025-02-13
release: 1.23.5
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.23.4 and Istio 1.23.5

{{< relnote >}}

## Changes

- **Fixed** a bug where mixed-case Hosts in Gateway and TLS redirect resulted in stale RDS.
  ([Issue #49638](https://github.com/istio/istio/issues/49638))

- **Fixed** an issue where ambient mode `PeerAuthentication` policies were overly strict.
  ([Issue #53884](https://github.com/istio/istio/issues/53884))

- **Fixed** a bug in where multiple STRICT port-level mTLS rules in an ambient mode PeerAuthentication policy would effectively result
in a permissive policy due to incorrect evaluation logic (AND vs. OR).
  ([Issue #54146](https://github.com/istio/istio/issues/54146))

- **Fixed** non-default revisions controlling gateways lacking `istio.io/rev` labels.
  ([Issue #54280](https://github.com/istio/istio/issues/54280))

- **Fixed** an issue where access log order instability caused connection draining.
  ([Issue #54672](https://github.com/istio/istio/issues/54672))

- **Fixed** a bug where Istiod would send an incompatible access log format to <1.23 proxies.
  ([Issue #54795](https://github.com/istio/istio/issues/54795))

- **Improved** Istiod's validation webhook to accept versions it does not know about.
This ensures that an older Istio can validate resources created by newer CRDs.

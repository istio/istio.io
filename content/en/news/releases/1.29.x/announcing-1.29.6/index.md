---
title: Announcing Istio 1.29.6
linktitle: 1.29.6
subtitle: Patch Release
description: Istio 1.29.6 patch release.
publishdate: 2026-07-16
release: 1.29.6
aliases:
    - /news/announcing-1.29.6
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.29.5 and 1.29.6.

{{< relnote >}}

## Changes

- **Fixed** an issue where `EXIT_ON_ZERO_ACTIVE_CONNECTIONS` never fired on ambient ingress gateways
  and waypoints because pilot-agent's drain loop counted in-process connections on Envoy's HBONE
  internal listeners (`connect_originate`, `connect_terminate`, `main_internal`, etc.), preventing
  the active-connection count from reaching zero and forcing the proxy to wait until
  `terminationGracePeriodSeconds`.
  ([Issue #60728](https://github.com/istio/istio/issues/60728))

- **Fixed** an issue where the advertised HBONE capability was not propagated onto auto-registered
  `WorkloadEntry` resources for non-Kubernetes workloads. Note that workloads auto-registered before
  upgrading continue to be reached over plaintext until they either re-register or the
  `networking.istio.io/tunnel=http` label is added to their existing `WorkloadEntry`.

- **Fixed** a deadlock in the ambient CNI node agent where a pod deletion event concurrent with a
  ztunnel (re)connection could permanently block the ZDS server.
  ([Issue ztunnel/1674](https://github.com/istio/ztunnel/issues/1674))

- **Fixed** a memory leak in Istiod where `needResync` entries for failed pod IPs were never cleaned up.

- **Fixed** cross-network traffic through the east-west gateway being blocked by a spurious
  deny-all RBAC filter when the destination service has L7 `AuthorizationPolicies`.
  ([Issue #60806](https://github.com/istio/istio/issues/60806))

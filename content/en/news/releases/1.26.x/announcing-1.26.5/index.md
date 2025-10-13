---
title: Announcing Istio 1.26.5
linktitle: 1.26.5
subtitle: Patch Release
description: Istio 1.26.5 patch release.
publishdate: 2025-10-13
release: 1.26.5
aliases:
    - /news/announcing-1.26.5
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.26.4 and Istio 1.26.5.

{{< relnote >}}

## Changes

- **Improved** access to referenced TLS secrets to require both namespace and service accounts to match (previously only the namespace), or to have an explicit `ReferenceGrant`, for Kubernetes Gateway API gateways. Gateways that use a hostname address remain namespace-only.

- **Added** the ability to turn off associating pods to proxies by IP address if association by name and namespace fails.
  This is on by default, matching the old behavior, and can be disabled with `ENABLE_PROXY_FIND_POD_BY_IP=off`.
  Future versions have this off by default.

- **Fixed** the cluster waypoint `correct_originate` configuration when `PILOT_SKIP_VALIDATE_TRUST_DOMAIN` is set. ([Issue #56741](https://github.com/istio/istio/issues/56741))

- **Fixed** an annotation issue where both `istio.io/reroute-virtual-interfaces` and the deprecated `traffic.sidecar.istio.io/kubevirtInterfaces` were processed. The newer `reroute-virtual-interfaces` annotation now correctly takes precedence. ([Issue #57662](https://github.com/istio/istio/issues/57662))

- **Fixed** `ServiceEntry` resolution in ztunnel to match port names to pod container ports, aligning behavior with sidecars, when there isn't an explicit `targetPort` set.
  ([Issue #57713](https://github.com/istio/istio/issues/57713))

- **Fixed** missing gateway reconciliation for MeshConfig changes. ([Issue #57890](https://github.com/istio/istio/issues/57890))

- **Removed** the istioctl installation dependency between pilot and CNI. CNI installation is no longer dependent on pilot being installed first. If the istio-cni configuration exists before installation (which can be the case when using an istio-owned CNI config), pilot installation will not fail while waiting for CNI readiness since CNI installation is no longer dependent on pilot. ([Issue #57600](https://github.com/istio/istio/issues/57600))

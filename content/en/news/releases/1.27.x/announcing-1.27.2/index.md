---
title: Announcing Istio 1.27.2
linktitle: 1.27.2
subtitle: Patch Release
description: Istio 1.27.2 patch release.
publishdate: 2025-10-13
release: 1.27.2
aliases:
    - /news/announcing-1.27.2
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.27.1 and 1.27.2.

{{< relnote >}}

## Changes

- **Improved** access to referenced TLS secrets to require both namespace and service accounts to match (previously only the namespace), or to have an explicit `ReferenceGrant`, for Kubernetes Gateway API gateways. Gateways that use a hostname address remain namespace-only.

- **Fixed** a goroutine leak in multicluster where `krt` collections with data from remote clusters would stay in memory even after that cluster was removed.
  ([Issue #57269](https://github.com/istio/istio/issues/57269))

- **Fixed** the behavior of istio-cni cleanup when the `get daemonset` command fails with an error other than "not found". It now defaults to not cleaning up the CNI config and binary when it cannot be determined whether an upgrade, deletion, or node reboot is in progress. ([Issue #57316](https://github.com/istio/istio/issues/57316))

- **Fixed** the cluster waypoint `correct_originate` configuration when `PILOT_SKIP_VALIDATE_TRUST_DOMAIN` is set.  ([Issue #56741](https://github.com/istio/istio/issues/56741))

- **Fixed** an annotation issue where both `istio.io/reroute-virtual-interfaces` and the deprecated `traffic.sidecar.istio.io/kubevirtInterfaces` were processed. The newer `reroute-virtual-interfaces` annotation now correctly takes precedence.  ([Issue #57662](https://github.com/istio/istio/issues/57662))

- **Fixed** `ServiceEntry` resolution in ztunnel to match port names to pod container ports, aligning behavior with sidecars, when there isn't an explicit `targetPort` set.
  ([Issue #57713](https://github.com/istio/istio/issues/57713))

- **Fixed** missing gateway reconciliation for MeshConfig changes. ([Issue #57890](https://github.com/istio/istio/issues/57890))

- **Removed** the istioctl installation dependency between pilot and CNI. CNI installation is no longer dependent on pilot being installed first. If the istio-cni configuration exists before installation (which can be the case when using an istio-owned CNI config), pilot installation will not fail while waiting for CNI readiness since CNI installation is no longer dependent on pilot.  ([Issue #57600](https://github.com/istio/istio/issues/57600))

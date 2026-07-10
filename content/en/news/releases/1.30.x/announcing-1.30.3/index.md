---
title: Announcing Istio 1.30.3
linktitle: 1.30.3
subtitle: Patch Release
description: Istio 1.30.3 patch release.
publishdate: 2026-07-16
release: 1.30.3
aliases:
    - /news/announcing-1.30.3
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.30.2 and 1.30.3.

{{< relnote >}}

## Changes

- **Added** support for a custom taint name for the pilot node untaint controller via the
  `PILOT_NODE_UNTAINT_CONTROLLERS_TAINT_NAME` environment variable. Defaults to `cni.istio.io/not-ready`.
  ([Issue #57844](https://github.com/istio/istio/issues/57844))

- **Improved** istiod scalability in ambient mode by scoping XDS pushes from workload/service
  `Address` changes to only the affected waypoints, instead of pushing to all waypoints and proxies.
  Can be disabled with `AMBIENT_SCOPED_ADDRESS_PUSHES=false`.

- **Fixed** pilot-agent missing certificate reloads on second and subsequent Kubernetes secret
  rotations for file-mounted certs.
  ([Issue #59912](https://github.com/istio/istio/issues/59912))

- **Fixed** an issue where additional namespaces in `meshConfig.defaultServiceExportTo` and
  `meshConfig.defaultVirtualServiceExportTo` were not being honored when the default included
  the current namespace as `.`.
  ([Issue #60560](https://github.com/istio/istio/issues/60560))

- **Fixed** a bug where istiod did not pick up updated remote cluster secrets (e.g. during
  credential/token rotation) until restarted. The new cluster registry could deadlock waiting
  to sync, leaving the service registry stale for the affected remote cluster.
  ([Issue #60612](https://github.com/istio/istio/issues/60612))

- **Fixed** an issue introduced in Istio 1.30 where metadata-only changes to VirtualService objects
  (e.g. Helm annotations, Argo CD labels, or `kubectl.kubernetes.io/last-applied-configuration`)
  triggered unnecessary XDS pushes to all proxies. This could cause a significant increase in
  control plane CPU usage and push latency in clusters with many VirtualServices managed by GitOps
  tooling. The fix restores the pre-1.30 behavior where only spec changes or `istio.io`
  label/annotation changes trigger a push.
  ([Issue #60629](https://github.com/istio/istio/issues/60629))

- **Fixed** a bug where a `Service` referring to a waypoint in a different namespace did not have
  the namespace-wide `Telemetry` resource included as part of its configuration.
  ([Issue #60665](https://github.com/istio/istio/issues/60665))

- **Fixed** default HTTP retries for inbound routes of waypoints. The mesh config's
  `defaultHttpRetryPolicy` will apply to local services attached to waypoints.
  ([Issue #60682](https://github.com/istio/istio/issues/60682))

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

- **Fixed** a bug where a `WasmPlugin` in an application namespace targeting a `Service` via `targetRefs`
  would cause a waypoint proxy to crash-loop on startup. The LDS path correctly included the plugin for
  the waypoint, but the ECDS lookup path rejected it as cross-namespace, leaving Envoy waiting for a
  resource that would never arrive.
  ([Issue #60530](https://github.com/istio/istio/issues/60530))

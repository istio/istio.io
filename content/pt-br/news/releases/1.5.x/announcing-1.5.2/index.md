---
title: Announcing Istio 1.5.2
linktitle: 1.5.2
subtitle: Patch Release
description: Istio 1.5.2 patch release.
publishdate: 2020-04-24
release: 1.5.2
aliases:
    - /news/announcing-1.5.2
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.5.1 and Istio 1.5.2.

{{< relnote >}}

## Changes

- **Fixed** Istiod deployment lacking label used by the matching `PodDisruptionBudget` ([Issue 22267](https://github.com/istio/istio/issues/22267))
- **Fixed** Custom Istio installation with istioctl not working using external charts ([Issue 22368](https://github.com/istio/istio/issues/22368))
- **Fixed** Panic in `istio-init` with GKE+COS and `interceptionMode`: TPROXY ([Issue 22500](https://github.com/istio/istio/issues/22500))
- **Fixed** Logging for validation by sending warnings to `stdErr` ([Issue 22496](https://github.com/istio/istio/issues/22496))
- **Fixed** Kiali not working when external Prometheus link used for the IstioOperator API ([Issue 22510](https://github.com/istio/istio/issues/22510))
- **Fixed** Istio agent should calculate grace period based on the cert TTL, not client-side settings ([Issue 22226](https://github.com/istio/istio/issues/22226)]
- **Fixed** Incorrect error message referring to incorrect CLI option for the `istioctl kube-inject` command ([Issue 22501](https://github.com/istio/istio/issues/22501))
- **Fixed** IstioOperator validation of slice ([Issue 21915](https://github.com/istio/istio/issues/21915))
- **Fixed** Race condition caused by read/write of `rootCert` and `rootCertExpireTime` not always being protected ([Issue 22627](https://github.com/istio/istio/issues/22627))
- **Fixed** BlackHoleCluster HTTP metrics broken with Telemetry v2 ([Issue 21385](https://github.com/istio/istio/issues/21385))
- **Fixed** `istio-init` container failing when Istio CNI is enabled ([Issue 22695](https://github.com/istio/istio/issues/22695))
- **Fixed** istioctl does not set gateway name for multiple gateways ([Issue 22703](https://github.com/istio/istio/issues/22703))
- **Fixed** Unstable inbound bind address when configuring a sidecar ingress listener without bind address ([Issue 22830](https://github.com/istio/istio/issues/22830))
- **Fixed** Proxy pods for Istio 1.4 not showing up when upgrading from Istio 1.4 to 1.5 using default profile ([Issue 22841](https://github.com/istio/istio/issues/22841))
- **Fixed** `PersistentVolumeClaim` for Grafana not being created in the namespace specified in the IstioOperator spec ([Issue 22835](https://github.com/istio/istio/issues/22835))
- **Fixed** `istio-sidecar-injector` and istiod related pods crashing when applying new manifest through istioctl because `alwaysInjectSelector` and `neverInjectSelector` are not correctly indented in the `istio-sidecar-injector` config map ([Issue 23027](https://github.com/istio/istio/issues/23027))
- **Fixed** Prometheus scraping failing in CNI injected pods because the default `excludeInboundPort` configuration does not include port 15090 ([Issue 23038](https://github.com/istio/istio/issues/23038))
- **Fixed** `Lightstep` secret volume issue causing the bundled Prometheus to not install correctly with Istio operator ([Issue 23078](https://github.com/istio/istio/issues/23078))
- **Fixed** Avoid using host header to extract destination service name at gateway in default Telemetry V2 configuration.
- **Fixed** Zipkin: Fix wrongly rendered timestamp value ([Issue 22968](https://github.com/istio/istio/issues/22968))
- **Improved** Add annotations for setting CPU/memory limits on sidecar ([Issue 16126](https://github.com/istio/istio/issues/16126))
- **Improved** Enable `rewriteAppHTTPProbe` annotation for liveness probe rewrite by default([Issue 10357](https://github.com/istio/istio/issues/10357))

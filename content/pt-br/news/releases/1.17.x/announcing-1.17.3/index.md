---
 title: Announcing Istio 1.17.3
 linktitle: 1.17.3
 subtitle: Patch Release
 description: Istio 1.17.3 patch release.
 publishdate: 2023-06-06
 release: 1.17.3
---

This release contains bug fixes to improve robustness. This release note describes what is different between Istio 1.17.2 and Istio 1.17.3.

{{< relnote >}}

## Changes

- **Added** support for `PodDisruptionBudget` (PDB) in the Gateway chart. [Issue #44469](https://github.com/istio/istio/issues/44469)
- **Fixed** an issue with forward compatibility with Istio 1.18+ [Kubernetes Gateway Automated Deployment](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment). To have a seamless upgrade to 1.18+, users of this feature should first adopt this patch release. [Issue #44164](https://github.com/istio/istio/issues/44164)
- **Fixed** The `dns_upstream_failures_total` metric was mistakenly deleted in the previous release. [PR #44176](https://github.com/istio/istio/pull/44176)
- **Fixed** an issue where grpc stats are absent. [Issue #43908](https://github.com/istio/istio/issues/43908), [Issue #44144](https://github.com/istio/istio/issues/44144)
- **Fixed** an issue where `Istio Gateway` (Envoy) would crash due to a duplicate `istio_authn` network filter in the Envoy filter chain. [Issue #44385](https://github.com/istio/istio/issues/44385)
- **Fixed** the VirtualService validation to fail on empty prefix header matcher. [Issue #44424](https://github.com/istio/istio/issues/44424)
- **Fixed** a bug where services are missing in gateways if `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG` is enabled. [Issue #44439](https://github.com/istio/istio/issues/44439)
- **Fixed** `istioctl analyze` no longer expects pods and runtime resources when analyzing files. [Issue #40861](https://github.com/istio/istio/issues/40861)
- **Fixed** `istioctl verify-install` fails when using multiple IOPs. [Issue #42964](https://github.com/istio/istio/issues/42964)
- **Fixed** handling of remote SPIFFE trust bundles containing multiple certificates.[PR #44909](https://github.com/istio/istio/pull/44909)
- **Fixed** CPU usage abnormally high when cert specified by DestinationRule are invalid. [Issue #44986](https://github.com/istio/istio/issues/44986)

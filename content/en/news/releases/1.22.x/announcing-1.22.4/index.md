---
title: Announcing Istio 1.22.4
linktitle: 1.22.4
subtitle: Patch Release
description: Istio 1.22.4 patch release.
publishdate: 2024-08-19
release: 1.22.4
---

This release note describes what is different between Istio 1.22.3 and 1.22.4.

{{< relnote >}}

## Changes

- **Fixed** VirtualMachine WorkloadEntry locality label missing during autoregistration.
  ([Issue #51800](https://github.com/istio/istio/issues/51800))

- **Fixed** matching multiple service VIPs in ServiceEntry.
  ([Issue #51747](https://github.com/istio/istio/issues/51747))

- **Fixed** inconsistent behavior with the `istio_agent_cert_expiry_seconds` metric.
  
- **Fixed** the istiod chart installation for older Helm versions (v3.6 and v3.7) by ensuring that `.Values.profile` is set to a string.
  ([Issue #52016](https://github.com/istio/istio/issues/52016))

- **Fixed** an omission in ztunnel helm charts which resulted in some Kubernetes resources being created without labels
  

- **Fixed** Do not add pod to ipset if we have a partial failure adding to the dataplane.
  ([Issue #52218](https://github.com/istio/istio/issues/52218))

- **Fixed** an issue causing resources to incorrectly be reported by `istioctl proxy-status` as `STALE`.
  ([Issue #51612](https://github.com/istio/istio/issues/51612))

- **Fixed** an issue that can trigger a deadlock when `discoverySelectors` (configured in `MeshConfig`) and a namespace,
which has an `Ingress` object or a `gateway.networking.k8s.io` `Gateway` object, moves from being selected to unselected.

- **Fixed** an issue causing stale endpoints when the same IP address was present in multiple `WorkloadEntries`.
  
- **Removed** writing the experimental field `GatewayClass.status.supportedFeatures`, as it is unstable in the API.

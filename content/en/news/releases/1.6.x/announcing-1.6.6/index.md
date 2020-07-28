---
title: Announcing Istio 1.6.6
linktitle: 1.6.6
subtitle: Patch Release
description: Istio 1.6.6 patch release.
publishdate: 2020-07-29
release: 1.6.6
aliases:
    - /news/announcing-1.6.6
---

This release contains bug fixes to improve robustness. This release note describes
what’s different between Istio 1.6.5 and Istio 1.6.6.

{{< relnote >}}

## Changes

- **Optimized** `ResolveGatewayName` to greatly reduce the CPU usage and number of memory allocations.
- **Fixed** `istioctl upgrade` so that it no longer checks remote component versions when using `--dry-run`. ([Issue 24865](https://github.com/istio/istio/issues/24865))
- **Fixed** long log messages for clusters with many gateways.
- **Fixed** route configuration generation to greatly reduce the load when processing virtual services on gateways. ([Issue 25116](https://github.com/istio/istio/issues/25116))
- **Fixed** outlier detection to only fire on gateway errors and not depend on success rate.([Issue 25220](https://github.com/istio/istio/issues/25220))
- **Fixed** demo profile to use port 15021 as the status port. Also general cleanup of unused resources. ([Issue #25626](https://github.com/istio/istio/issues/25626))
- **Fixed** Galley to properly handle errors from Kubernetes tombstones.
- **Fixed** Istio to encrypt traffic between sidecars and egress gateways.([Issue 23910](https://github.com/istio/istio/issues/23910))
- **Fixed** Bookinfo demo application to verify if a specified namespace exists and if not, use the default namespace.
- **Added** `pilot_xds` label in order to give more information on data plane versions without scraping the data plane. 
- **Added** `CA_ADDR` field to allow configuring the certificate authority address on the egress gateway configuration and fixed the `istio-certs` mount secret name.
- **Updated** Istiod to trigger an endpoint update when a new pod comes in.
- **Updated** Bookinfo demo application to latest versions of libraries. 
- **Updated** Istio to disable auto mTLS when the cluster type is `Cluster_ORIGINAL_DST`.

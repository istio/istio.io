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

{{< warning >}}
This release contains a regression from 1.6.5 that prevents endpoints not associated with pods from working. Please upgrade to 1.6.7 when it is available.
{{< /warning >}}

This release contains bug fixes to improve robustness. This release note describes
what’s different between Istio 1.6.5 and Istio 1.6.6.

{{< relnote >}}

## Changes

- **Optimized** performance in scenarios with large numbers of gateways. ([Issue 25116](https://github.com/istio/istio/issues/25116))
- **Fixed** an issue where out of order events may cause the Istiod update queue to get stuck. This resulted in proxies with stale configuration.
- **Fixed** `istioctl upgrade` so that it no longer checks remote component versions when using `--dry-run`. ([Issue 24865](https://github.com/istio/istio/issues/24865))
- **Fixed** long log messages for clusters with many gateways.
- **Fixed** outlier detection to only fire on user configured errors and not depend on success rate. ([Issue 25220](https://github.com/istio/istio/issues/25220))
- **Fixed** demo profile to use port 15021 as the status port. ([Issue #25626](https://github.com/istio/istio/issues/25626))
- **Fixed** Galley to properly handle errors from Kubernetes tombstones.
- **Fixed** an issue where manually enabling TLS/mTLS for communication between a sidecar and an egress gateway did not work. ([Issue 23910](https://github.com/istio/istio/issues/23910))
- **Fixed** Bookinfo demo application to verify if a specified namespace exists and if not, use the default namespace.
- **Added** a label to the `pilot_xds` metric in order to give more information on data plane versions without scraping the data plane.
- **Added** `CA_ADDR` field to allow configuring the certificate authority address on the egress gateway configuration and fixed the `istio-certs` mount secret name.
- **Updated** Bookinfo demo application to latest versions of libraries.
- **Updated** Istio to disable auto mTLS when sending traffic to headless services without a sidecar.

---
title: Announcing Istio 1.5.6
linktitle: 1.5.6
subtitle: Patch Release
description: Istio 1.5.6 patch release.
publishdate: 2020-06-17
release: 1.5.6
aliases:
    - /news/announcing-1.5.6
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.5.5 and Istio 1.5.6.

{{< relnote >}}

## Security

- **Updated** Node.js and jQuery versions used in bookinfo.

## Changes

- **Fixed** Transfer-Encoding value case-sensitivity in Envoy ([Envoy's issue 10041](https://github.com/envoyproxy/envoy/issues/10041))
- **Fixed** handling of user defined ingress gateway configuration ([Issue 23303](https://github.com/istio/istio/issues/23303))
- **Fixed** Add `TCP MX ALPN` in `UpstreamTlsContext` for clusters that specify `http2_protocol_options` ([Issue 23907](https://github.com/istio/istio/issues/23907))
- **Fixed** election lock for namespace configmap controller.
- **Fixed** `istioctl validate -f` for `networking.istio.io/v1beta1` rules ([Issue 24064](https://github.com/istio/istio/issues/24064))
- **Fixed** aggregate clusters configuration ([Issue 23909](https://github.com/istio/istio/issues/23909))
- **Fixed** Prometheus mTLS poods scraping ([Issue 22391](https://github.com/istio/istio/issues/22391))
- **Fixed** ingress crash for overlapping hosts without match ([Issue 22910](https://github.com/istio/istio/issues/22910))
- **Fixed** Istio telemetry Pod crashes ([Issue 23813](https://github.com/istio/istio/issues/23813))
- **Removed** hard-coded operator namespace ([Issue 24073](https://github.com/istio/istio/issues/24073))

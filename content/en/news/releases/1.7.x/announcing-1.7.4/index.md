---
title: Announcing Istio 1.7.4
linktitle: 1.7.4
subtitle: Patch Release
description: Istio 1.7.4 patch release.
publishdate: 2020-10-27
release: 1.7.4
aliases:
    - /news/announcing-1.7.4
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.7.3 and Istio 1.7.4

{{< relnote >}}

## Changes

- **Improved** TLS configuration on sidecar server-side inbound paths to enforce TLS 2.0 version along with recommended cipher suites. This is disabled by default and can enabled by setting the environment variable `PILOT_SIDECAR_ENABLE_INBOUND_TLS_V2` to true.

- **Added** ability to configure domain suffix for multicluster installation. ([Issue #27300](https://github.com/istio/istio/issues/27300))

- **Added** `istioctl proxy-status` and other commands will attempt to contact the control plane using both port-forwarding and exec before giving up, restoring functionality on clusters that do not offer port-forwarding to the control plane. ([Issue #27421](https://github.com/istio/istio/issues/27421))

- **Added** support for `securityContext` in the Kubernetes settings for the operator API. ([Issue #26275](https://github.com/istio/istio/issues/26275))

- **Added** support for revision based istiod to istioctl version. ([Issue #27756](https://github.com/istio/istio/issues/27756))

- **Fixed** deleting the remote-secret for multicluster installation removes remote endpoints.

- **Fixed** an issue that Istiod’s `cacert.pem` is under the `testdata` directory. ([Issue #27574](https://github.com/istio/istio/issues/27574))

- **Fixed** `PodDisruptionBudget` of `istio-egressgateway` does not match any pods. ([Issue #27730](https://github.com/istio/istio/issues/27730))

- **Fixed** an issue preventing calls to wildcard (such as *.example.com) domains when a port is set in the Host header.

- **Fixed** an issue periodically causing a deadlock in Pilot’s `syncz` debug endpoint.

- **Removed** deprecated `outboundTrafficPolicy` from global values. ([Issue #27494](https://github.com/istio/istio/issues/27494))

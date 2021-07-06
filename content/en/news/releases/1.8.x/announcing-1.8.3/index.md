---
title: Announcing Istio 1.8.3
linktitle: 1.8.3
subtitle: Patch Release
description: Istio 1.8.3 patch release.
publishdate: 2021-02-08
release: 1.8.3
aliases:
    - /news/announcing-1.8.3
---

This release contains bug fixes to improve stability. This release note describes what’s different between Istio 1.8.2 and Istio 1.8.3

{{< relnote >}}

## Security

Istio 1.8.3 will not contain a security fix as previously announced on [discuss.istio.io](https://discuss.istio.io/t/upcoming-istio-1-7-8-and-1-8-3-security-release/9593).
There is no currently planned date at this time. Be assured that this is a top priority for the Istio Product Security Working Group, but due to the details we cannot release more information at this time. An announcement regarding the delay can be found [here](https://discuss.istio.io/t/istio-1-7-8-and-1-8-3-cve-fixes-delayed/9663).

## Changes

- **Fixed** an issue with aggregate cluster during TLS init in Envoy
  ([Issue #28620](https://github.com/istio/istio/issues/28620))

- **Fixed** an issue causing Istio 1.8 to configure Istio 1.7 proxies incorrectly when using the `Sidecar` `ingress` configuration.
  ([Issue #30437](https://github.com/istio/istio/issues/30437))

- **Fixed** a bug where DNS agent preview produces malformed DNS responses.
  ([Issue #28970](https://github.com/istio/istio/issues/28970))

- **Fixed** a bug where the env K8S settings are overridden by the env settings in the helm values.
  ([Issue #30079](https://github.com/istio/istio/issues/30079))

- **Fixed** a bug where `istioctl dashboard controlz` could not port forward to istiod pod.
  ([Issue #30208](https://github.com/istio/istio/issues/30208))

- **Fixed** a bug that prevented `Ingress` resources created with `IngressClass` from having their status field updated
  ([Issue #25308](https://github.com/istio/istio/issues/25308))

- **Fixed** an issue where the `TLSv2` version was enforced only on HTTP ports. This option is now applied to all ports.
  ([PR #30590](https://github.com/istio/istio/pull/30590))

- **Fixed** issues resulting in missing routes when using `httpsRedirect` in a `Gateway`.
  ([Issue #27315](https://github.com/istio/istio/issues/27315)),([Issue #27157](https://github.com/istio/istio/issues/27157))

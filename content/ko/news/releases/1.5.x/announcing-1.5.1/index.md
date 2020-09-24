---
title: Announcing Istio 1.5.1
linktitle: 1.5.1
subtitle: Patch Release
description: Istio 1.5.1 patch release.
publishdate: 2020-03-25
release: 1.5.1
aliases:
    - /news/announcing-1.5.1
---

This release contains bug fixes to improve robustness and fixes for the security vulnerabilities described in [our March 25th, 2020 news post](/news/security/istio-security-2020-004). This release note describes what’s different between Istio 1.5.0 and Istio 1.5.1.

{{< relnote >}}

## Security update

- **ISTIO-SECURITY-2020-004** Istio uses a hard coded `signing_key` for Kiali.

__[CVE-2020-1764](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-1764)__: Istio uses a default `signing key` to install Kiali. This can allow an attacker with access to Kiali to bypass authentication and gain administrative privileges over Istio.
In addition, another CVE is fixed in this release, described in the Kiali 1.15.1 [release](https://kiali.io/news/security-bulletins/kiali-security-001/).

## Changes

- **Fixed** an issue where Istio Operator instance deletion hangs for  in-cluster operator ([Issue 22280](https://github.com/istio/istio/issues/22280))
- **Fixed** istioctl proxy-status should not list differences if just the order of the routes have changed ([Issue 21709](https://github.com/istio/istio/issues/21709))
- **Fixed** Incomplete support for array notation in "istioctl manifest apply —set" ([Issue 20950](https://github.com/istio/istio/issues/20950))
- **Fixed** Add possibility to add annotations to services in Kubernetes service spec ([Issue 21995](https://github.com/istio/istio/issues/21995))
- **Fixed** Enable setting ILB Gateway using istioctl ([Issue 20033](https://github.com/istio/istio/issues/20033))
- **Fixed** istioctl does not correctly set names on gateways ([Issue 21938](https://github.com/istio/istio/issues/21938))
- **Fixed** OpenID discovery does not work with beta request authentication policy ([Issue 21954](https://github.com/istio/istio/issues/21954))
- **Fixed** Issues related to shared control plane multicluster ([Issue 22173](https://github.com/istio/istio/pull/22173))
- **Fixed** Ingress port displaying target port instead of actual port ([Issue 22125](https://github.com/istio/istio/issues/22125))
- **Fixed** Issue where endpoints were being pruned automatically when installing the Istio Controller ([Issue 21495](https://github.com/istio/istio/issues/21495))
- **Fixed** Add istiod port to gateways for mesh expansion([Issue 22027](https://github.com/istio/istio/issues/22027))
- **Fixed** Multicluster secret controller silently ignoring updates to secrets ([Issue 18708](https://github.com/istio/istio/issues/18708))
- **Fixed** Autoscaler for mixer-telemetry always being generated when deploying with istioctl or Helm ([Issue 20935](https://github.com/istio/istio/issues/20935))
- **Fixed** Prometheus certificate provisioning is broken ([Issue 21843](https://github.com/istio/istio/issues/21843))
- **Fixed** Segmentation fault in Pilot with beta mutual TLS ([Issue 21816](https://github.com/istio/istio/issues/21816))
- **Fixed** Operator status enumeration not being rendered as a string ([Issue 21554](https://github.com/istio/istio/issues/21554))
- **Fixed** in-cluster operator fails to install control plane after having deleted a prior control plane ([Issue 21467](https://github.com/istio/istio/issues/21467))
- **Fixed** TCP metrics for BlackHole clusters does not work with Telemetry v2 ([Issue 21566](https://github.com/istio/istio/issues/21566))
- **Improved** Add option to enable V8 runtime for telemetry V2 ([Issue 21846](https://github.com/istio/istio/pull/21846))
- **Improved** compatibility of Helm gateway chart ([Issue 22295](https://github.com/istio/istio/pull/22295))
- **Improved** operator by adding a Helm installation chart ([Issue 21861](https://github.com/istio/istio/issues/21861))
- **Improved** Support custom CA on istio-agent ([Issue 22113](https://github.com/istio/istio/pull/22113))
- **Improved** Add a flag that supports passing GCP metadata to STS ([Issue 21904](https://github.com/istio/istio/issues/21904))

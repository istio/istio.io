---
title: Announcing Istio 1.3.7
linktitle: 1.3.7
description: Istio 1.3.7 patch release.
publishdate: 2020-02-04
subtitle: Patch Release
release: 1.3.7
aliases:
    - /news/announcing-1.3.7
---

This release includes bug fixes to improve robustness. This release note describes what's different between Istio 1.3.6 and Istio 1.3.7.

{{< relnote >}}

## Bug fixes

* **Fixed** root certificate rotation in Citadel to reuse values from the expiring root certificate into the new root certificate ([Issue 19644](https://github.com/istio/istio/issues/19644)).
* **Fixed** telemetry to ignore forwarded attributes at the gateway.
* **Fixed** sidecar injection into pods with containers that export no port ([Issue 18594](https://github.com/istio/istio/issues/18594)).
* **Added** telemetry support for pod names containing periods ([Issue 19015](https://github.com/istio/istio/issues/19015)).
* **Added** support for generating `PKCS#8` private keys in Citadel agent ([Issue 19948](https://github.com/istio/istio/issues/19948)).

## Minor enhancements

* **Improved** injection template to fully specify `securityContext`, allowing `PodSecurityPolicies` to properly validate injected deployments ([Issue 17318](https://github.com/istio/istio/issues/17318)).
* **Added** support for setting the `lifecycle` for proxy containers.
* **Added** support for setting the Mesh UID in the Stackdriver Mixer adapter ([Issue 17952](https://github.com/istio/istio/issues/17952)).

## Security update

* [**ISTIO-SECURITY-2020-002**](/news/security/istio-security-2020-002) Mixer policy check bypass caused by improperly accepting certain request headers.

__[CVE-2020-8843](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8843)__: Under certain circumstances it is possible to bypass a specifically configured Mixer policy. Istio-proxy accepts `x-istio-attributes` header at ingress that can be used to affect policy decisions when Mixer policy selectively applies to source equal to ingress. Istio 1.3 to 1.3.6 is vulnerable.

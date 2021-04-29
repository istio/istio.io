---
title: Announcing Istio 1.4.10
linktitle: 1.4.10
subtitle: Patch Release
description: Istio 1.4.10 security release.
publishdate: 2020-06-22
release: 1.4.10
aliases:
    - /news/announcing-1.4.10
---

This is the final release for Istio 1.4.

This release fixes the security vulnerability described in [our June 11th, 2020 news post](/news/security/istio-security-2020-006)
as well as bug fixes to improve robustness.

This release note describes what's different between Istio 1.4.9 and Istio 1.4.10.

{{< relnote >}}

## Security update

- **ISTIO-SECURITY-2020-006** Excessive CPU usage when processing HTTP/2 SETTINGS frames with too many parameters, potentially leading to a denial of service.

__[CVE-2020-11080](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-11080)__: By sending a specially crafted packet, an attacker could cause the CPU to spike at 100%. This could be sent to the ingress gateway or a sidecar.

## Bug fixes

- **Fixed** `istio-cni-node` crash when `COS_CONTAINERD` and Istio CNI are enabled when running on Google Kubernetes Engine ([Issue 23643](https://github.com/istio/istio/issues/23643))
- **Fixed** Istio CNI causes pod initialization to experience a 30-40 second delay on startup when DNS is unreachable ([Issue 23770](https://github.com/istio/istio/issues/23770))

## Bookinfo sample application security fixes

We've updated the versions of Node.js and jQuery used in the Bookinfo sample application. Node.js has been upgraded from
version 12.9 to 12.18. jQuery has been updated from version 2.1.4 to version 3.5.0. The highest rated vulnerability fixed:
*HTTP request smuggling using malformed Transfer-Encoding header (Critical) (CVE-2019-15605)*

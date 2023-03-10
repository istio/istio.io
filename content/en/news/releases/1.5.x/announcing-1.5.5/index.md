---
title: Announcing Istio 1.5.5
linktitle: 1.5.5
subtitle: Patch Release
description: Istio 1.5.5 security release.
publishdate: 2020-06-11
release: 1.5.5
aliases:
    - /news/announcing-1.5.5
---

This release fixes the security vulnerability described in [our June 11th, 2020 news post](/news/security/istio-security-2020-006).

This release note describes what's different between Istio 1.5.5 and Istio 1.5.4.

{{< relnote >}}

## Security update

- **ISTIO-SECURITY-2020-006** Excessive CPU usage when processing HTTP/2 SETTINGS frames with too many parameters, potentially leading to a denial of service.

__[CVE-2020-11080](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-11080)__: By sending a specially crafted packet, an attacker could cause the CPU to spike at 100%. This could be sent to the ingress gateway or a sidecar.

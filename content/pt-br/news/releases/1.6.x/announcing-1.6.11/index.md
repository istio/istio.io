---
title: Announcing Istio 1.6.11
linktitle: 1.6.11
subtitle: Security Release
description: Istio 1.6.11 security release.
publishdate: 2020-09-29
release: 1.6.11
aliases:
    - /news/announcing-1.6.11
---

This release fixes the security vulnerability described in [our September 29 post](/news/security/istio-security-2020-010).

{{< relnote >}}

## Security update

- __[CVE-2020-25017](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-25017)__:
In some cases, Envoy only considers the first value when multiple headers are present. Also, Envoy does not replace all existing occurrences of a non-inline header.
    - __CVSS Score__: 8.3 [AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L&version=3.1)

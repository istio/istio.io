---
title: Announcing Istio 1.5.9
linktitle: 1.5.9
subtitle: Patch Release
description: Istio 1.5.9 security release.
publishdate: 2020-08-11
release: 1.5.9
aliases:
    - /news/announcing-1.5.9
---

This release fixes the security vulnerability described in [our August 11th, 2020 news post](/news/security/istio-security-2020-009).

These release notes describe what's different between Istio 1.5.8 and Istio 1.5.9.

{{< relnote >}}

## Security update

- __[CVE-2020-16844](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-16844)__:
Callers to TCP services that have a defined Authorization Policies with `DENY` actions using wildcard suffixes (e.g. `*-some-suffix`) for source principals or namespace fields will never be denied access.
    - CVSS Score: 6.8 [AV:N/AC:H/PR:L/UI:N/S:U/C:H/I:H/A:N](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:H/PR:L/UI:N/S:U/C:H/I:H/A:N&version=3.1)

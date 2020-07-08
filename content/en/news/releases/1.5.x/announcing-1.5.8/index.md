---
title: Announcing Istio 1.5.8
linktitle: 1.5.8
subtitle: Patch Release
description: Istio 1.5.8 security release.
publishdate: 2020-07-09
release: 1.5.8
aliases:
    - /news/announcing-1.5.8
---

This release fixes the security vulnerability described in [our July 9th, 2020 news post](/news/security/istio-security-2020-008).

This release note describes what's different between Istio 1.5.8 and Istio 1.5.7.

{{< relnote >}}

## Security update

- __[`CVE-2020-15104`](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-15104)__:
When validating TLS certificates, Envoy incorrectly allows a wildcard DNS Subject Alternative Name apply to multiple subdomains. For example, with a SAN of `*.example.com`, Envoy incorrectly allows `nested.subdomain.example.com`, when it should only allow `subdomain.example.com`.
    - CVSS Score: 6.6 [AV:N/AC:H/PR:H/UI:N/S:C/C:H/I:L/A:N/E:F/RL:O/RC:C](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:H/PR:H/UI:N/S:C/C:H/I:L/A:N/E:F/RL:O/RC:C&version=3.1)


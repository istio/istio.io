---
title: ISTIO-SECURITY-2020-010
subtitle: Security Bulletin
description:
cves: [CVE-2020-25017]
cvss: "8.3"
vector: "AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L"
releases: ["1.6 to 1.6.10", "1.7 to 1.7.2"]
publishdate: 2020-09-29
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Envoy, and subsequently Istio, is vulnerable to a newly discovered vulnerability:

- __[CVE-2020-25017](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-25017)__:
In some cases, Envoy only considers the first value when multiple headers are present. Also, Envoy does not replace all existing occurrences of a non-inline header.
    - __CVSS Score__: 8.3 [AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L&version=3.1)

## Mitigation

- For Istio 1.6.x deployments: update to [Istio 1.6.11](/news/releases/1.6.x/announcing-1.6.11) or later.
- For Istio 1.7.x deployments: update to [Istio 1.7.3](/news/releases/1.7.x/announcing-1.7.3) or later.

{{< boilerplate "security-vulnerability" >}}

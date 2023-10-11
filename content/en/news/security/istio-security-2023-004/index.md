---
title: ISTIO-SECURITY-2023-004
subtitle: Security Bulletin
description: CVEs reported by Envoy and Go.
cves: [CVE-2023-44487, CVE-2023-39325]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.17.0", "1.17.0 to 1.17.6", "1.18.0 to 1.18.3", "1.19.0 to 1.19.1"]
publishdate: 2023-10-11
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE

- __[`CVE-2023-44487`](https://nvd.nist.gov/vuln/detail/CVE-2023-44487)__: (CVSS Score 7.5, High): HTTP/2 denial of service

### Go CVE

- __[`CVE-2023-39325`](https://github.com/golang/go/issues/63417)__: (CVSS Score 7.5, High): HTTP/2 denial of service

## Am I Impacted?

You are impacted If you accept HTTP/2 traffic from untrusted sources, which applies to most users. This especially applies if you use a Gateway exposed on the public internet.

---
title: ISTIO-SECURITY-2024-002
subtitle: Security Bulletin
description: CVEs reported by Envoy and Go.
cves: [CVE-2024-27919, CVE-2024-30255, CVE-2023-45288]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.19.0", "1.19.0 to 1.19.8", "1.20.0 to 1.20.4", "1.21.0"]
publishdate: 2024-04-08
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2024-27919](https://github.com/envoyproxy/envoy/security/advisories/GHSA-gghf-vfxp-799r)__: (CVSS Score 7.5, High): HTTP/2: memory exhaustion due to CONTINUATION frame flood.
- __[CVE-2024-30255](https://github.com/envoyproxy/envoy/security/advisories/GHSA-j654-3ccm-vfmm)__: (CVSS Score 5.3, Moderate): HTTP/2: CPU exhaustion due to CONTINUATION frame flood.

### Go CVEs

*NOTE*: At the time of publishing, the CVE was not yet scored or vectored.

- __[CVE-2023-45288](https://nvd.nist.gov/vuln/detail/CVE-2023-45288)__: (CVSS Score Unpublished): HTTP/2 CONTINUATION frames can be utilized for DoS attacks.

## Am I Impacted?

You are impacted if you accept HTTP/2 traffic from untrusted sources, which applies to most users. This especially applies if you use a Gateway exposed on the public internet.

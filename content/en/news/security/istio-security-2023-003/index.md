---
title: ISTIO-SECURITY-2023-003
subtitle: Security Bulletin
description: CVEs reported by Envoy.
cves: [CVE-2023-35941,CVE-2023-35942,CVE-2023-35943,CVE-2023-35944]
cvss: "8.6"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:L"
releases: ["All releases prior to 1.16.0", "1.16.0 to 1.16.6", "1.17.0 to 1.17.4", "1.18.0 to 1.18.1"]
publishdate: 2023-07-25
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2023-35941](https://github.com/envoyproxy/envoy/security/advisories/GHSA-7mhv-gr67-hq55)__: (CVSS Score 8.6, High): OAuth2 credentials exploit with permanent validity.
- __[CVE-2023-35942](https://github.com/envoyproxy/envoy/security/advisories/GHSA-69vr-g55c-v2v4)__: (CVSS Score 6.5, Moderate): gRPC access log crash caused by the listener draining.
- __[CVE-2023-35943](https://github.com/envoyproxy/envoy/security/advisories/GHSA-mc6h-6j9x-v3gq)__: (CVSS Score 6.3, Moderate): CORS filter segfault when origin header is removed.
- __[CVE-2023-35944](https://github.com/envoyproxy/envoy/security/advisories/GHSA-pvgm-7jpg-pw5g)__: (CVSS Score 8.2, High): Incorrect handling of HTTP requests and responses with mixed case schemes in Envoy.

## Am I Impacted?

You are impacted If you accept HTTP/2 traffic from untrusted sources, which applies to most users. This especially applies if you use a Gateway exposed on the public internet.

---
title: ISTIO-SECURITY-2023-003
subtitle: Security Bulletin
description: CVEs reported by Envoy.
cves: [CVE-2023-35941,CVE-2023-35942,CVE-2023-35943,CVE-2023-35944]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.16.0", "1.16.0 to 1.16.6", "1.17.0 to 1.17.4", "1.18.0 to 1.18.1"]
publishdate: 2023-07-14
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2023-35945](https://github.com/envoyproxy/envoy/security/advisories/GHSA-jfxv-29pc-x22r)__: (CVSS Score 7.5, High):
HTTP/2 memory leak in `nghttp2` codec.

- __CVE-2023-35941__: (CVSS Score 8.6, High): OAuth2 credentials exploit with permanent validity.
- __CVE-2023-35942__: (CVSS Score 6.5, Moderate): gRPC access log crash caused by the listener draining.
- __CVE-2023-35943__: (CVSS Score 6.3, Moderate): CORS filter segfault when origin header is removed.
- __CVE-2023-35944__: (CVSS Score 8.2, High): Incorrect handling of HTTP requests and responses with mixed case schemes in Envoy.

## Am I Impacted?

If you accept HTTP/2 traffic from untrusted sources, which applies to most users. This especially applies if you use a Gateway exposed on the public internet.

---
title: ISTIO-SECURITY-2023-002
subtitle: Security Bulletin
description: CVE reported by Envoy.
cves: [CVE-2023-35945]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.16.0", "1.16.0 to 1.16.5", "1.17.0 to 1.17.3", "1.18.0"]
publishdate: 2023-04-04
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2023-35945](https://github.com/envoyproxy/envoy/security/advisories/GHSA-jfxv-29pc-x22r)__: (CVSS Score 7.5, High):
HTTP/2 memory leak in `nghttp2` codec.

## Am I Impacted?

You may be at risk if you have an Istio gateway or if you use external istiod.

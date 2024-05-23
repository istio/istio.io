---
title: ISTIO-SECURITY-2024-003
subtitle: Security Bulletin
description: CVEs reported by Envoy.
cves: [CVE-2024-32475]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.19.0", "1.19.0 to 1.19.9", "1.20.0 to 1.20.5", "1.21.0 to 1.21.1"]
publishdate: 2024-04-22
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2024-32475](https://github.com/envoyproxy/envoy/security/advisories/GHSA-3mh5-6q8v-25wj)__: (CVSS Score 7.5, High): Abnormal termination when using `auto_sni` with `:authority` header longer than 255 characters.

## Am I Impacted?

You are impacted if you enabled the `auto_sni` feature of Envoy, are using Istio versions 1.21.0 or above where this was enabled by default, or
are using an Egress Gateway.

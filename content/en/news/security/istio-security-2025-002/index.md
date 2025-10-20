---
title: ISTIO-SECURITY-2025-001
subtitle: Security Bulletin
description: CVEs reported by Envoy.
cves: [CVE-2025-55162, CVE-2025-54588]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.27.0", "1.26.0 to 1.26.3", "1.25.0 to 1.25.4"]
publishdate: 2025-09-03
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2025-55162](https://github.com/envoyproxy/envoy/security/advisories/GHSA-95j4-hw7f-v2rh)__: (CVSS score 6.3, Moderate): OAuth2 Filter Signout route will not clear cookies because of missing "secure;" flag
- __[CVE-2025-54588](https://github.com/envoyproxy/envoy/security/advisories/GHSA-g9vw-6pvx-7gmw)__: (CVSS score 7.5, High): Use after free in DNS cache

## Am I Impacted?

You are impacted if you are using Istio 1.27.0, 1.26.0 to 1.26.3, or 1.25.0 to 1.25.4, and you use cookies named with prefix `__Secure-` or `__Host-`, or you are using `EnvoyFilter` with `dynamic_forward_proxy`.

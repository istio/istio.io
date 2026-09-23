---
title: ISTIO-SECURITY-2025-003
subtitle: Security Bulletin
description: CVEs reported by Envoy.
cves: [CVE-2025-66220, CVE-2025-64527, CVE-2025-64763]
cvss: "8.1"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N"
releases: ["1.28.0", "1.27.0 to 1.27.3", "1.26.0 to 1.26.6"]
publishdate: 2025-12-03
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2025-66220](https://nvd.nist.gov/vuln/detail/CVE-2025-66220)__: (CVSS score 8.1, High): TLS certificate matcher for `match_typed_subject_alt_names`
may incorrectly treat certificates with `OTHERNAME` SANs containing an embedded null byte as valid.
- __[CVE-2025-64527](https://nvd.nist.gov/vuln/detail/CVE-2025-64527)__: (CVSS score 6.5, Medium): Envoy crashes when JWT authentication is configured with
the remote JWKS fetching.
- __[CVE-2025-64763](https://nvd.nist.gov/vuln/detail/CVE-2025-64763)__: (CVSS score 5.3, Medium): Potential request smuggling from early data after the
CONNECT upgrade

## Am I Impacted?

If you are using Istio to accept WebSocket traffic, you are potentially vulnerable to request smuggling from early data after the CONNECT upgrade. You may also be vulnerable if you are using custom certificates with OTHERNAME SANs or custom JWT authentication with remote JWKS fetching using `EnvoyFilter`.

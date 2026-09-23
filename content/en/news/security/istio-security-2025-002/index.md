---
title: ISTIO-SECURITY-2025-002
subtitle: Security Bulletin
description: CVEs reported by Envoy.
cves: [CVE-2025-55162, CVE-2025-54588]
cvss: "6.6"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.27.0 to 1.27.1", "1.26.0 to 1.26.5"]
publishdate: 2025-10-20
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2025-62504](https://nvd.nist.gov/vuln/detail/CVE-2025-62504)__: (CVSS score 6.5, Medium): Lua modified large enough response body will cause Envoy to crash.
- __[CVE-2025-62409](https://nvd.nist.gov/vuln/detail/CVE-2025-62409)__: (CVSS score 6.6, Medium): Large requests and responses can cause TCP connection pool crash.

## Am I Impacted?

You are impacted if you use Lua via `EnvoyFilter` that returns an oversized response body exceeding the `per_connection_buffer_limit_bytes` (default 1MB) or where you have large requests
and responses where a connection can be closed but data from upstream is still being sent.

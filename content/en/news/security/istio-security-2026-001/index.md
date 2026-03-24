---
title: ISTIO-SECURITY-2026-001
subtitle: Security Bulletin
description: CVEs reported by Envoy and Istio security fixes.
cves: [CVE-2026-26308, CVE-2026-26309, CVE-2026-26310, CVE-2026-26311, CVE-2026-26330, CVE-2026-31837, CVE-2026-31838]
cvss: "8.7"
vector: "CVSS:3.1/AV:N/AC:H/PR:N/UI:N/S:C/C:H/I:L/A:N"
releases: ["1.29.0", "1.28.0 to 1.28.4", "1.27.0 to 1.27.7"]
publishdate: 2026-03-10
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2026-26308](https://nvd.nist.gov/vuln/detail/CVE-2026-26308)__: (CVSS score 7.5, High): Fixed RBAC header matcher to validate each header value individually instead of concatenating multiple header values into a single string. This prevents potential bypasses when requests contain multiple values for the same header.
- __[CVE-2026-26311](https://nvd.nist.gov/vuln/detail/CVE-2026-26311)__: (CVSS score 5.9, Medium): Fixed an issue where filter chain execution could continue on HTTP streams that had been reset but not yet destroyed, potentially causing use-after-free conditions.
- __[CVE-2026-26310](https://nvd.nist.gov/vuln/detail/CVE-2026-26310)__: (CVSS score 5.9, Medium): Fixed a crash in `Utility::getAddressWithPort` when called with a scoped IPv6 address (e.g., `fe80::1%eth0`).
- __[CVE-2026-26309](https://nvd.nist.gov/vuln/detail/CVE-2026-26309)__: (CVSS score 5.3, Medium): Fixed an off-by-one write in `JsonEscaper::escapeString()` that could corrupt the string null terminator.
- __[CVE-2026-26330](https://nvd.nist.gov/vuln/detail/CVE-2026-26330)__: (CVSS score 5.3, Medium): Fixed a bug in the gRPC rate limit client that could lead to potential use-after-free issues. Only affects Istio 1.28 and 1.29.

### Istio CVEs

- __[CVE-2026-31838](https://nvd.nist.gov/vuln/detail/CVE-2026-31838)__ / __[GHSA-974c-2wxh-g4ww](https://github.com/istio/istio/security/advisories/GHSA-974c-2wxh-g4ww)__: (CVSS score 6.9, Medium): Debug Endpoints Allow Cross-Namespace Proxy Data Access.
  Reported by [1seal](https://github.com/1seal).
- __[CVE-2026-31837](https://nvd.nist.gov/vuln/detail/CVE-2026-31837)__ / __[GHSA-v75c-crr9-733c](https://github.com/istio/istio/security/advisories/GHSA-v75c-crr9-733c)__: (CVSS score 8.7, High): JWKS Resolver Failure May Allow Authentication Bypass Using Known Default Keys.
  Reported by [1seal](https://github.com/1seal).

### Other Istio Security Fixes

- **Fixed** XDS debug endpoints on plaintext port 15010 to require authentication, preventing unauthenticated access to proxy configuration.
  Reported by [1seal](https://github.com/1seal).
- **Fixed** potential SSRF in `WasmPlugin` image fetching by validating bearer token realm URLs.
  Reported by [Sergey Kanibor (Luntry)](https://github.com/r0binak).
- **Fixed** HTTP debug endpoints on port 15014 to enforce namespace-based authorization, preventing cross-namespace proxy data access.
  Reported by [Sergey Kanibor (Luntry)](https://github.com/r0binak).

## Am I Impacted?

All users running affected Istio versions are potentially impacted.

- The Envoy RBAC header matching vulnerability can be exploited when authorization policies match on headers that may contain multiple values, allowing policy bypass.

- The JWKS resolver vulnerability could allow authentication bypass when a JWKS fetch fails, as istiod falls back to publicly known default keys that an attacker can use to forge valid JWTs. Users with `RequestAuthentication` resources configured with `jwksUri` are directly impacted.

- The XDS debug endpoint vulnerability allowed unauthenticated access to debug endpoints (such as `config_dump`) on the plaintext XDS port 15010, which could leak sensitive proxy configuration to any workload with network access to istiod. After upgrading, debug endpoint authentication is enabled by default. The `ENABLE_DEBUG_ENDPOINT_AUTH` and `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` environment variables can be used to adjust compatibility with legacy systems if required.

- The SSRF vulnerability in `WasmPlugin` image fetching could allow an attacker to redirect bearer token credentials to an arbitrary URL.

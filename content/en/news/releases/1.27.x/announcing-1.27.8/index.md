---
title: Announcing Istio 1.27.8
linktitle: 1.27.8
subtitle: Patch Release
description: Istio 1.27.8 patch release.
publishdate: 2026-03-10
release: 1.27.8
aliases:
    - /news/announcing-1.27.8
---

This release contains security fixes. This release note describes what's different between Istio 1.27.7 and 1.27.8.

{{< relnote >}}

## Security update

For more information, see [ISTIO-SECURITY-2026-001](/news/security/istio-security-2026-001).

### Envoy CVEs

- [CVE-2026-26308](https://nvd.nist.gov/vuln/detail/CVE-2026-26308) (CVSS score 7.5, High): Fix multivalue header bypass in RBAC.
- [CVE-2026-26311](https://nvd.nist.gov/vuln/detail/CVE-2026-26311) (CVSS score 5.9, Medium): HTTP decode methods blocked after downstream reset.
- [CVE-2026-26310](https://nvd.nist.gov/vuln/detail/CVE-2026-26310) (CVSS score 5.9, Medium): Fix crash in `getAddressWithPort()` with scoped IPv6 address.
- [CVE-2026-26309](https://nvd.nist.gov/vuln/detail/CVE-2026-26309) (CVSS score 5.3, Medium): JSON off-by-one write fix.

### Istio CVEs

- __[CVE-2026-31838](https://nvd.nist.gov/vuln/detail/CVE-2026-31838)__ / __[GHSA-974c-2wxh-g4ww](https://github.com/istio/istio/security/advisories/GHSA-974c-2wxh-g4ww)__: (CVSS score 6.9, Medium): Debug Endpoints Allow Cross-Namespace Proxy Data Access.
  Reported by [1seal](https://github.com/1seal).
- __[CVE-2026-31837](https://nvd.nist.gov/vuln/detail/CVE-2026-31837)__ / __[GHSA-v75c-crr9-733c](https://github.com/istio/istio/security/advisories/GHSA-v75c-crr9-733c)__: (CVSS score 8.7, High): JWKS Resolver Failure May Allow Authentication Bypass Using Known Default Keys.
  Reported by [1seal](https://github.com/1seal).

### Istio Security Fixes

- **Fixed** XDS debug endpoints on plaintext port 15010 to require authentication, preventing unauthenticated access to proxy configuration.
  Reported by [1seal](https://github.com/1seal).
- **Fixed** potential SSRF in `WasmPlugin` image fetching by validating bearer token realm URLs.
  Reported by [Sergey Kanibor (Luntry)](https://github.com/r0binak).
- **Fixed** HTTP debug endpoints on port 15014 to enforce namespace-based authorization, preventing cross-namespace proxy data access.
  Reported by [Sergey Kanibor (Luntry)](https://github.com/r0binak).
- **Added** the ability to specify authorized namespaces for debug endpoints when `ENABLE_DEBUG_ENDPOINT_AUTH=true`. Enable by
  setting `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` to a comma separated list of authorized namespaces. The system namespace
  (typically `istio-system`) is always authorized.

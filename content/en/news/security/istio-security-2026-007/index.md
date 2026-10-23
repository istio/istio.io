---
title: ISTIO-SECURITY-2026-007
subtitle: Security Bulletin
description: CVEs reported by Envoy, plus Istio security fixes for an AuthorizationPolicy method-case bypass over HTTP/2 and an istiod denial of service in ambient mode.
cves: [CVE-2026-111497]
cvss: "9.2"
vector: "CVSS:4.0/AV:N/AC:L/AT:P/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N"
cvss_version: "4.0"
releases: ["1.31.0 to 1.31.1", "1.30.0 to 1.30.5", "1.29.0 to 1.29.8"]
publishdate: 2026-10-15
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[GHSA-8vc2-jrm4-835w](https://github.com/envoyproxy/envoy/security/advisories/GHSA-8vc2-jrm4-835w)__: (CVSS score 7.5): Fixed an unauthenticated remote crash (null pointer dereference) in the OAuth2 HTTP filter when handling a CONNECT request without a `:path` header.
- __[GHSA-47vj-9r25-wv5j](https://github.com/envoyproxy/envoy/security/advisories/GHSA-47vj-9r25-wv5j)__: (CVSS score 6.5): Fixed a crash in the `api_key_auth` HTTP filter when hiding credentials on a CONNECT request without a `:path` header.
- __[CVE-2026-111497](https://nvd.nist.gov/vuln/detail/CVE-2026-111497)__ ([GHSA-3wvj-j6qm-62mr](https://github.com/envoyproxy/envoy/security/advisories/GHSA-3wvj-j6qm-62mr)): (CVSS score 9.2, Critical): Fixed a buffer overflow in the Brotli decompressor that could allow a remote unauthenticated attacker to disclose memory contents, crash the proxy, or potentially execute arbitrary code. Users who enable Brotli decompression, for example with an `EnvoyFilter`, should upgrade. **Credit**: This vulnerability was discovered and reported by OpenAI Security Research.

### Istio CVEs

- __[GHSA-w44g-8m76-8gc5](https://github.com/istio/istio/security/advisories/GHSA-w44g-8m76-8gc5)__ (CVSS score 7.4, High): `AuthorizationPolicy` method rules are bypassed over HTTP/2 by changing the case of the method. **Credit**: This vulnerability was discovered and reported by [izzy0101010101](https://github.com/izzy0101010101).
- __[GHSA-7p2q-4xvg-vxc6](https://github.com/istio/istio/security/advisories/GHSA-7p2q-4xvg-vxc6)__ (CVSS score 7.7, High): istiod crashes (denial of service) in ambient mode when a `ServiceEntry` or other service claims the address of an IP-addressed waypoint. **Credit**: This vulnerability was discovered and reported by [yshch](https://github.com/yshch).

## `AuthorizationPolicy` method rules bypassed over HTTP/2

An `AuthorizationPolicy` `DENY` rule with `methods` (or an `ALLOW` rule with `notMethods`) was compiled to a case-sensitive `:method` matcher. Over HTTP/2, a request whose method differs only in case (for example `post` instead of `POST`) did not match the rule and was forwarded to the workload, bypassing the policy. HTTP/1.1 is not affected because the codec rejects non-uppercase methods before authorization. Method matching is now case-insensitive.

## istiod denial of service via waypoint address collision

In ambient mode, istiod resolves the service that owns an IP-addressed waypoint by network and IP address only. When a second service, such as a `ServiceEntry` in any namespace, claimed the same address, istiod panicked and crash-looped until the colliding resource was removed. A user allowed to create `ServiceEntry` resources in their own namespace could stop configuration distribution and certificate rotation for the whole mesh. Colliding addresses are now skipped with a warning.

## Am I Impacted?

- **Envoy CVEs:** You are potentially impacted if you run an affected Istio release and use the OAuth2 or `api_key_auth` HTTP filters, or enable Brotli decompression.

- **`AuthorizationPolicy` method bypass:** You are impacted if you use `AuthorizationPolicy` `DENY` rules with `methods`, or `ALLOW` rules with `notMethods`, and clients can reach the workload over HTTP/2. Policies that only use `ALLOW` rules with an explicit `methods` list are not affected.

- **istiod denial of service:** You are impacted if you run ambient mode with an IP-addressed waypoint (for example a waypoint `Gateway` annotated with `networking.istio.io/address-type: IPAddress`) and users other than mesh administrators can create `ServiceEntry` resources. Waypoints that report a hostname, which is the default, are not affected.

## Mitigation

- For Istio 1.31 users: upgrade to **1.31.2** or later.
- For Istio 1.30 users: upgrade to **1.30.6** or later.
- For Istio 1.29 users: upgrade to **1.29.9**. This is the final 1.29 release, as [1.29 reached end of life](/news/support/announcing-1.29-eol/) on October 15, 2026. Plan an upgrade to 1.30 or later.
- As an interim measure for the `AuthorizationPolicy` bypass, use `ALLOW` policies with an explicit `methods` allow-list instead of `DENY` or `notMethods` rules.
- As an interim measure for the istiod denial of service, restrict `ServiceEntry` create and update permissions to trusted administrators using Kubernetes RBAC, or use hostname-addressed waypoints.

## Other Istio Security Fixes

This release also includes the following security fixes that were not assigned CVEs. See the release notes for each version for details.

- `istioctl` now verifies the istiod certificate when connecting to XDS with a service account token. **Credit**: This issue was reported by [Leon Zlobecki](https://leonz.is).
- `istioctl manifest translate` now escapes values written into generated install shell scripts. **Credit**: This vulnerability was discovered and reported by OpenSec Intelligence.
- Fixed an istiod panic when the OIDC/JWT authenticator received a token with a malformed `sub` claim. **Credit**: This issue was reported by Kaizhe Huang.
- Hardened the experimental Kubernetes CSR RA path (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`): opaque errors to callers, a bounded watch loop, and a new `MAX_RA_WORKLOAD_CERT_TTL` cap. **Credit**: This issue was reported by Juno Im.
- The Wasm OCI image fetcher no longer falls back to plaintext HTTP for registries that are not listed in `WASM_INSECURE_REGISTRIES`. **Credit**: This vulnerability was discovered and reported by Adam Korczynski.
- istiod debug endpoints now require an exact `proxyID` match. **Credit**: This issue was reported by 박현범.
- Added `PILOT_ENABLE_STRICT_GATEWAY_MERGING` to 1.29 and 1.30 to prevent cross-namespace merging of Istio `Gateway` resources with managed Gateway API gateways. It is disabled by default in 1.29 and 1.30 and enabled by default starting in 1.31.

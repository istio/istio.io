---
title: ISTIO-SECURITY-2026-006
subtitle: Security Bulletin
description: CVEs reported by Envoy, plus Istio security fixes for an EnvoyFilter control-plane denial of service and a BackendTLSPolicy fail-open on sidecars.
cves: [CVE-2026-73513, CVE-2026-73552, CVE-2026-73512, CVE-2026-73547, CVE-2026-73549, CVE-2026-50572, CVE-2026-73546, CVE-2026-48521, CVE-2026-73551, CVE-2026-73511, CVE-2026-73548, CVE-2026-73550, CVE-2026-73553, CVE-XXXX-XXXXX]
cvss: "7.7"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:N/I:N/A:H"
releases: ["1.29.0 to 1.29.6", "1.30.0 to 1.30.3"]
publishdate: 2026-08-26
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2026-73513](https://nvd.nist.gov/vuln/detail/CVE-2026-73513)__: (CVSS score 7.5): Fixed a heap use-after-free where an untrusted upstream could send HTTP/2 response trailers without the `END_STREAM` flag to an Envoy instance using `oghttp2`, corrupting stream state and terminating the process.
- __[CVE-2026-73552](https://nvd.nist.gov/vuln/detail/CVE-2026-73552)__: (CVSS score 7.5): Fixed an issue where `safe_regex` matching treated accepted non-UTF-8 HTTP header bytes as a non-match; in RBAC policies using negative matching this could fail open and allow access to a protected resource.
- __[CVE-2026-73512](https://nvd.nist.gov/vuln/detail/CVE-2026-73512)__: (CVSS score 7.5): Fixed a use-after-free in the QUIC HTTP datagram handler where late HTTP/3 datagrams could reference a stream decoder that was already destroyed or replaced.
- __[CVE-2026-73547](https://nvd.nist.gov/vuln/detail/CVE-2026-73547)__: (CVSS score 7.5): Fixed an abnormal process termination in the `ext_authz` filter when processing CONNECT requests without a `:path` pseudo-header.
- __[CVE-2026-73549](https://nvd.nist.gov/vuln/detail/CVE-2026-73549)__: (CVSS score 5.3): Fixed an abnormal process termination for scoped IPv6 client addresses in original DST clusters with HTTP/3.
- __[CVE-2026-50572](https://nvd.nist.gov/vuln/detail/CVE-2026-50572)__: (CVSS score 5.9): Fixed a use-after-free in the `ext_authz` raw HTTP client where completing an authorization request could destroy the client while its completion handler was still executing.
- __[CVE-2026-73546](https://nvd.nist.gov/vuln/detail/CVE-2026-73546)__: (CVSS score 7.4): Fixed a stored cross-site scripting issue in the HTML stats interface (`/stats?format=html`) where dynamically named statistics could introduce attacker-controlled content.
- __[CVE-2026-48521](https://nvd.nist.gov/vuln/detail/CVE-2026-48521)__: (CVSS score 5.9): Fixed an abnormal process termination where Envoy could dereference null transport socket options during ALPN-based HTTP/3 connection-pool selection.
- __[CVE-2026-73551](https://nvd.nist.gov/vuln/detail/CVE-2026-73551)__: (CVSS score 5.3): Fixed URL normalization of dot and dot-dot path segments containing parameters, which could cause access-control components and upstream applications to interpret a request path differently.
- __[CVE-2026-73511](https://nvd.nist.gov/vuln/detail/CVE-2026-73511)__: (CVSS score 5.3): Fixed path matching for paths containing per-segment parameters, where Envoy and backends could select different resources for the same request and bypass path-based selection or authentication.
- __[CVE-2026-73548](https://nvd.nist.gov/vuln/detail/CVE-2026-73548)__: (CVSS score 7.5): Fixed cross-user response poisoning involving generic, non-WebSocket HTTP upgrades, where request payload sent before an upgrade was accepted could contaminate a shared upstream connection.
- __[CVE-2026-73550](https://nvd.nist.gov/vuln/detail/CVE-2026-73550)__: (CVSS score 7.5): Fixed an HTTP/2 memory-exhaustion issue where discarded duplicate Host headers were not counted toward request-header size and count limits.
- __[CVE-2026-73553](https://nvd.nist.gov/vuln/detail/CVE-2026-73553)__: (CVSS score 7.5): Fixed an authorization bypass when `ignore_path_parameters_in_path_matching` was enabled, where a path such as `/admin;x` could bypass an RBAC policy for `/admin` while still reaching the protected route.

### Istio CVEs

- __[CVE-XXXX-XXXXX](https://nvd.nist.gov/vuln/detail/CVE-XXXX-XXXXX)__ / __[GHSA-qm8v-g4f9-qhjx](https://github.com/istio/istio/security/advisories/GHSA-qm8v-g4f9-qhjx)__: (CVSS score 6.8): Fixed `BackendTLSPolicy` failing open to plaintext on sidecar proxies when its CA certificate reference is unresolved.
  Reported by [@thc1006](https://github.com/thc1006).

## Control plane denial of service via `EnvoyFilter` `proxyVersion`

The `proxyVersion` match expression in the `EnvoyFilter` resource (`spec.configPatches[].match.proxy.proxyVersion`) accepted a regular expression of unbounded length. Istiod compiles this expression during admission validation and again during configuration distribution. A user with permission to create `EnvoyFilter` resources in a single namespace could submit very large expressions that drive excessive memory and CPU usage in istiod, potentially crashing the control plane. Because the validating webhook is configured to fail closed, configuration changes for all namespaces in the mesh are rejected while istiod is unavailable, extending the impact beyond the attacker's own namespace.

Older, unsupported Istio releases are also affected.

The `proxyVersion` match expression is now limited to 1024 characters.

## Am I Impacted?

- **Envoy CVEs:** You are potentially impacted if you run an affected Istio release, which bundles the affected Envoy proxy. The specific exposure depends on the features in use (for example HTTP/3, `ext_authz`, RBAC, or the admin stats interface); see each CVE above.

- **EnvoyFilter denial of service:** You are impacted if users other than mesh administrators are allowed to create or update `EnvoyFilter` resources, for example in namespace-based multi-tenant environments. Meshes where only administrators can manage `EnvoyFilter` resources are not exposed to untrusted input, but should still upgrade.

- **BackendTLSPolicy fail-open:** You are impacted if you use a `BackendTLSPolicy` for mesh (sidecar) upstream traffic and the policy's `caCertificateRefs` can become unresolvable (for example, the referenced `ConfigMap` is deleted, renamed, or absent). In that case the sidecar sends the upstream traffic in plaintext instead of blocking it, losing the encryption and CA validation the policy required. Gateway (ingress) proxies are not impacted; they fail closed.

## Mitigation

- For Istio 1.30 users: upgrade to **1.30.4** or later.
- For Istio 1.29 users: upgrade to **1.29.7** or later.
- As an interim measure for the `EnvoyFilter` denial of service, restrict `EnvoyFilter` create and update permissions to trusted administrators using Kubernetes RBAC.

The Istio Security Committee would like to thank [`Artem Cherezov`](https://github.com/cherez0ff) and [`@thc1006`](https://github.com/thc1006) for responsibly disclosing these issues.

---
title: ISTIO-SECURITY-2024-001
subtitle: Security Bulletin
description: CVEs reported by Envoy.
cves: [CVE-2024-23322, CVE-2024-23323, CVE-2024-23324, CVE-2024-23325, CVE-2024-23327]
cvss: "8.6"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:N/A:N"
releases: ["All releases prior to 1.19.0", "1.19.0 to 1.19.6", "1.20.0 to 1.20.2"]
publishdate: 2024-02-09
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

**Note**: At the time of publishing, the below security advisories have not yet been published, but should be published shortly.

- __[CVE-2024-23322](https://github.com/envoyproxy/envoy/security/advisories/GHSA-6p83-mfmh-qv38)__: (CVSS Score 7.5, High): Envoy crashes when idle and request per try timeout occur within the backoff interval.
- __[CVE-2024-23323](https://github.com/envoyproxy/envoy/security/advisories/GHSA-x278-4w4x-r7ch)__: (CVSS Score 4.3, Moderate): Excessive CPU usage when URI template matcher is configured using regex.
- __[CVE-2024-23324](https://github.com/envoyproxy/envoy/security/advisories/GHSA-gq3v-vvhj-96j6)__: (CVSS Score 8.6, High): Ext auth can be bypassed when Proxy protocol filter sets invalid UTF-8 metadata.
- __[CVE-2024-23325](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5m7c-mrwr-pm26)__: (CVSS Score 7.5, High): Envoy crashes when using an address type that isn't supported by the OS.
- __[CVE-2024-23327](https://github.com/envoyproxy/envoy/security/advisories/GHSA-4h5x-x9vh-m29j)__: (CVSS Score 7.5, High): Crash in proxy protocol when command type of LOCAL.

## Am I Impacted?

The majority of exploitable behavior is related to the use of PROXY Protocol, primarily used in gateway scenarios. If you or your users have PROXY Protocol enabled, either via `EnvoyFilter` or [proxy config](/docs/ops/configuration/traffic-management/network-topologies/#proxy-protocol) annotations, there is potential exposure.

Aside from the use of PROXY protocol, the usage of the `%DOWNSTREAM_PEER_IP_SAN%` [command operator](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage.html#command-operators) for access logs has potential exposure.

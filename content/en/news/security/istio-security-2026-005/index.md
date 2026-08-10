---
title: ISTIO-SECURITY-2026-005
subtitle: Security Bulletin
description: CVEs reported by Envoy and Istio security fixes.
cves: [CVE-2026-47692, CVE-2026-47207, CVE-2026-47205, CVE-2026-47220, CVE-2026-47221, CVE-2026-48044, CVE-2026-48090, CVE-2026-47778, CVE-2026-47204, CVE-2026-48497, CVE-2026-48706, CVE-2026-48743, CVE-2026-47775, CVE-2026-48042]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:H/PR:N/UI:N/S:C/C:H/I:L/A:N"
releases: ["1.30.1 to 1.30.2", "1.29.4 to 1.29.5", "1.28.8 to 1.28.9"]
publishdate: 2026-06-24
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[GHSA-p7c7-7c47-pwch](https://github.com/envoyproxy/envoy/security/advisories/GHSA-p7c7-7c47-pwch)__: (CVSS score 7.5): Fixed a denial-of-service vulnerability in the HTTP/3 stack via QPACK blocked decoding. When a QPACK header block was blocked waiting for dynamic table updates, the HEADERS payload bytes were released from QUIC receive-flow-control accounting while still retained in an internal decoder heap buffer, allowing a remote attacker to drive unbounded memory growth and trigger an out-of-memory condition.
- __[CVE-2026-47692](https://nvd.nist.gov/vuln/detail/CVE-2026-47692)__: (CVSS score 4.8): Fixed a bug where passthrough TLVs combined with added TLVs could exceed the maximum length, resulting in a mismatch between the size reported in the header and the number of bytes written. This could allow a smuggled request from the host writing the PROXY protocol header to the upstream host.
- __[CVE-2026-47207](https://nvd.nist.gov/vuln/detail/CVE-2026-47207)__: (CVSS score 6.5): Fixed a bug where the `ext_proc` server sends unexpected `ProcessingResponses` to Envoy.
- __[CVE-2026-47205](https://nvd.nist.gov/vuln/detail/CVE-2026-47205)__: (CVSS score 5.9): Fixed a use-after-free crash in the ext_authz filter when per-route service overrides are active and the downstream connection resets during an in-flight authorization check.
- __[CVE-2026-47220](https://nvd.nist.gov/vuln/detail/CVE-2026-47220)__: (CVSS score 7.5): Fixed a crash bug in the `%REQUESTED_SERVER_NAME%` formatter where the host or original host is not set correctly but the formatter is configured to access the host value.
- __[CVE-2026-47221](https://nvd.nist.gov/vuln/detail/CVE-2026-47221)__: (CVSS score 5.9): Fixed an issue when handling HTTP 303 internal redirects for body-less requests. The redirect handling code attempted to drain a request body buffer that was never allocated, causing a segmentation fault.
- __[CVE-2026-48044](https://nvd.nist.gov/vuln/detail/CVE-2026-48044)__: (CVSS score 7.5): Fixed a memory exhaustion vulnerability in the Zstd decompressor where the `MaxInflateRatio` limit was only checked after each input slice was fully processed, allowing a maliciously crafted compressed payload to expand to hundreds of MB within a single `process()` call. The inflate ratio limit is now enforced inside the inner decompression loop, matching the gzip and brotli decompressors and aborting decompression as soon as the threshold is breached.
- __[CVE-2026-48090](https://nvd.nist.gov/vuln/detail/CVE-2026-48090)__: (CVSS score 5.9): Fixed a bug where the asynchronous token change callback could be triggered after the filter had been torn down (`onDestroy()` had been called), which could lead to accessing dangling pointers and result in UAF/crash.
- __[CVE-2026-47778](https://nvd.nist.gov/vuln/detail/CVE-2026-47778)__: (CVSS score 4.4): Fixed an issue where Envoy could fail to validate the Subject Alternative Name (SAN) of a peer certificate if the SAN contained an embedded NUL byte. Previously, the SAN parsing was vulnerable to NUL byte truncation in some configurations, potentially leading to incorrect trust decisions.
- __[CVE-2026-47204](https://nvd.nist.gov/vuln/detail/CVE-2026-47204)__: (CVSS score 6.5): Fixed a crash or use-after-free when gRPC stats filter performs stat tracking on a direct response route.
- __[CVE-2026-48497](https://nvd.nist.gov/vuln/detail/CVE-2026-48497)__: (CVSS score 5.9): Fixed sanity checking of the query name length to avoid abnormal process termination. Use `ENVOY_BUG` in case the sanity check fails.
- __[CVE-2026-48706](https://nvd.nist.gov/vuln/detail/CVE-2026-48706)__: (CVSS score 5.9): Fixed a `TcpStatsdSink` buffer overflow issue with a large stats name.
- __[CVE-2026-48743](https://nvd.nist.gov/vuln/detail/CVE-2026-48743)__: (CVSS score 7.5): Fixed HTTP/3 headers-only request and response content-length validation and reset stream if inconsistent. The change is guarded by runtime guard `envoy.reloadable_features.quic_validate_headers_only_content_length`.
- __[CVE-2026-47775](https://nvd.nist.gov/vuln/detail/CVE-2026-47775)__: (CVSS score 6.8): Addressed a padding oracle in the OAuth2 filter's AES-256-CBC cookie decryption. The filter now supports AES-256-GCM encryption with a `gcm.` algorithm marker, which authenticates the ciphertext and removes the oracle.
- __[CVE-2026-48042](https://nvd.nist.gov/vuln/detail/CVE-2026-48042)__: (CVSS score 7.5): Limited JSON nesting depth to 1000. The limit could be relaxed to 10K by setting the `envoy.reloadable_features.limit_json_parser_nesting_depth` to `false`.

---
title: ISTIO-SECURITY-2024-004
subtitle: Security Bulletin
description: CVEs reported by Envoy.
cves: [CVE-2024-32976, CVE-2024-32975, CVE-2024-32974, CVE-2024-34363, CVE-2024-34362, CVE-2024-23326, CVE-2024-34364]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.20.0", "1.20.0 to 1.20.6", "1.21.0 to 1.21.2", "1.22.0"]
publishdate: 2024-06-04
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2024-23326](https://github.com/envoyproxy/envoy/security/advisories/GHSA-vcf8-7238-v74c)__: (CVSS Score 5.9, Moderate): Incorrect handling of responses to HTTP/1 upgrade requests that can lead to request smuggling.

- __[CVE-2024-32974](https://github.com/envoyproxy/envoy/security/advisories/GHSA-mgxp-7hhp-8299)__: (CVSS Score 5.9, Moderate): Vulnerability in QUIC stack that can lead to abnormal process termination.

- __[CVE-2024-32975](https://github.com/envoyproxy/envoy/security/advisories/GHSA-g9mq-6v96-cpqc)__: (CVSS Score 5.9, Moderate): Vulnerability in QUIC stack that can lead to abnormal process termination.

- __[CVE-2024-32976](https://github.com/envoyproxy/envoy/security/advisories/GHSA-7wp5-c2vq-4f8m)__: (CVSS Score 7.5, High): Vulnerability in `Brotli` decompressor that can lead to infinite loop.

- __[CVE-2024-34362](https://github.com/envoyproxy/envoy/security/advisories/GHSA-hww5-43gv-35jv)__: (CVSS Score 5.9, Moderate): Vulnerability in QUIC stack that can lead to abnormal process termination.

- __[CVE-2024-34363](https://github.com/envoyproxy/envoy/security/advisories/GHSA-g979-ph9j-5gg4)__: (CVSS Score 7.5, High): Vulnerability in Envoy access log JSON formatter, that can lead to abnormal process termination.

- __[CVE-2024-34364](https://github.com/envoyproxy/envoy/security/advisories/GHSA-xcj3-h7vf-fw26)__: (CVSS Score 5.7, Moderate): Unbounded memory consumption in `ext_proc` and `ext_authz`.

## Am I Impacted?

If you are using JSON access log formatting in Istio 1.22, you are impacted, please upgrade as soon as possible. The request smuggling will also affect users of Websockets.

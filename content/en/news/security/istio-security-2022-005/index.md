---
title: ISTIO-SECURITY-2022-005
subtitle: Security Bulletin
description: Ill-formed headers sent to Envoy in certain configurations can lead to unexpected memory access resulting in undefined behavior or crashing.
cves: [CVE-2022-31045, CVE-2022-29225, CVE-2022-29224, CVE-2022-29226, CVE-2022-29228, CVE-2022-29227]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.12.0", "1.12.0 to 1.12.7", "1.13.0 to 1.13.4", "1.14.0"]
publishdate: 2022-06-09
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-31045

- [CVE-2022-31045](https://github.com/istio/istio/security/advisories/GHSA-xwx5-5c9g-x68x) (CVSS score 5.9, Medium): Memory access violation
Ill-formed headers sent to Envoy in certain configurations can lead to unexpected memory access, resulting in undefined behavior or crashing.

### Envoy CVEs

These Envoy CVEs do not directly impact Istio features, but we will still include them in the patch releases for 1.12.8, 1.13.5 and 1.14.1.

- [CVE-2022-29225](https://github.com/envoyproxy/envoy/security/advisories/GHSA-75hv-2jjj-89hh) (CVSS score 7.5, High): Decompressors can be zip bombed
Decompressors accumulate decompressed data into an intermediate buffer before overwriting the body in the `decode/encodeBody`. This may allow an attacker to zip bomb the decompressor by sending a small highly compressed payload.

- [CVE-2022-29224](https://github.com/envoyproxy/envoy/security/advisories/GHSA-m4j9-86g3-8f49) (CVSS score 5.9, Medium): Segfault in `GrpcHealthCheckerImpl`
An attacker-controlled upstream server that is health checked using gRPC health checking can crash Envoy via a null pointer dereference in certain circumstances.

- [CVE-2022-29226](https://github.com/envoyproxy/envoy/security/advisories/GHSA-h45c-2f94-prxh) (CVSS score 10.0, Critical): OAuth filter allows trivial bypass
The OAuth filter implementation does not include a mechanism for validating access tokens, so by design when the HMAC signed cookie is missing a full authentication flow should be triggered. However, the current implementation assumes that access tokens are always validated thus allowing access in the presence of any access token attached to the request.

- [CVE-2022-29228](https://github.com/envoyproxy/envoy/security/advisories/GHSA-rww6-8h7g-8jf6) (CVSS score 7.5, High): OAuth filter calls `continueDecoding()` from within `decodeHeaders()`
The OAuth filter would try to invoke the remaining filters in the chain after emitting a local response, which triggers an ASSERT() in newer versions and corrupts memory on earlier versions.

- [CVE-2022-29227](https://github.com/envoyproxy/envoy/security/advisories/GHSA-rm2p-qvf6-pvr6) (CVSS score 7.5, High): Internal redirect crash for requests with body/trailers
Envoy internal redirects for requests with bodies or trailers are not safe if the redirect prompts an Envoy-generated local reply.

## Am I Impacted?

You are at most risk if you you have an Istio ingress Gateway exposed to external traffic.

## Credit

We would like to thank Otto van der Schaaf of Red Hat for the report.

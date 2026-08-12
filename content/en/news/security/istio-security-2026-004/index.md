---
title: ISTIO-SECURITY-2026-004
subtitle: Security Bulletin
description: CVE reported by Envoy.
cves: [CVE-2026-47774]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.30.0", "1.29.0 to 1.29.3", "1.28.0 to 1.28.7"]
publishdate: 2026-06-04
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2026-47774](https://github.com/envoyproxy/envoy/security/advisories/GHSA-22m2-hvr2-xqc8)__: (CVSS score 7.5, High): HTTP/2 memory exhaustion via cookie header HPACK amplification.
  Cookie header bytes are not fully accounted for during request header size validation, and HPACK header
  block limits are enforced on encoded bytes without a corresponding limit on total decoded header size.
  An unauthenticated remote attacker can exploit this to exhaust memory in the Envoy process, causing
  denial of service through OOM termination.

## Am I Impacted?

You are impacted if you are running an affected version of Istio and accept downstream HTTP/2 traffic.
This includes any Istio deployment that exposes services to external clients or untrusted workloads over
HTTP/2 or gRPC, as an attacker can send specially crafted requests with large cookie headers to trigger
excessive memory consumption.

## Mitigation

- For Istio 1.30 users: Upgrade to **1.30.1** or later.
- For Istio 1.29 users: Upgrade to **1.29.4** or later.
- For Istio 1.28 users: Upgrade to **1.28.8** or later.

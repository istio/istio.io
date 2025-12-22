---
title: ISTIO-SECURITY-2025-004
subtitle: Security Bulletin
description: CVEs reported by Envoy.
cves: [CVE-2025-62408]
cvss: "5.3"
vector: "CVSS:3.1/AV:L/AC:L/PR:L/UI:N/S:U/C:N/I:H/A:N"
releases: ["1.28.0 to 1.28.1", "1.27.0 to 1.27.4", "1.26.0 to 1.26.7"]
publishdate: 2025-12-22
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2025-62408](https://github.com/envoyproxy/envoy/security/advisories/GHSA-fg9g-pvc4-776f)__: (CVSS score 5.3, Moderate): Use after free can crash Envoy due to malfunctioning or compromised DNS. This is a heap use-after-free vulnerability in the c-ares library that can be exploited by an attacker controlling the local DNS infrastructure to cause a Denial of Service (DoS) in Envoy.

## Am I Impacted?

You are potentially vulnerable if:

- Your Istio deployment relies on DNS resolution through c-ares library (which is the default for Envoy)
- An attacker has control over your local DNS infrastructure or can compromise DNS responses
- Your environment allows malicious or malfunctioning DNS servers to send crafted responses

This vulnerability affects Envoy's DNS resolution functionality and could cause service mesh proxies to crash when processing specially crafted DNS responses. While this is a potentially severe bug, it has limited exploitability, as any attacker would require control of the DNS infrastructure.

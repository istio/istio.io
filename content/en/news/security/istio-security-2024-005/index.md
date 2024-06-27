---
title: ISTIO-SECURITY-2024-005
subtitle: Security Bulletin
description: CVEs reported by Envoy.
cves: []
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.21.0 to 1.21.3", "1.22.0 to 1.22.1"]
publishdate: 2024-06-27
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[GHSA-8mq4-c2v5-3h39](https://github.com/envoyproxy/envoy/security/advisories/GHSA-8mq4-c2v5-3h39)__: (CVSS Score 7.5, Moderate): Datadog: Datadog tracer does not handle trace headers with Unicode characters.

## Am I Impacted?

You are impacted if you are using Istio 1.21.0 to 1.21.3 or 1.22.0 to 1.22.1 and have enabled the Datadog tracer.

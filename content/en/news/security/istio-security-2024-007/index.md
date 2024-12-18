---
title: ISTIO-SECURITY-2024-007
subtitle: Security Bulletin
description: CVEs reported by Envoy.
cves: [CVE-2024-53269, CVE-2024-53270, CVE-2024-53271]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.22.0 to 1.22.6", "1.23.0 to 1.23.3", "1.24.0 to 1.24.1"]
publishdate: 2024-12-18
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __[CVE-2024-53269](https://github.com/envoyproxy/envoy/security/advisories/GHSA-mfqp-7mmj-rm53)__: (CVSS Score 4.5, Moderate): Happy Eyeballs: Validate that `additional_address` are IP addresses instead of crashing when sorting.
- __[CVE-2024-53270](https://github.com/envoyproxy/envoy/security/advisories/GHSA-q9qv-8j52-77p3)__: (CVSS Score 7.5, High): HTTP/1: sending overload crashes when the request is reset beforehand.
- __[CVE-2024-53271](https://github.com/envoyproxy/envoy/security/advisories/GHSA-rmm5-h2wv-mg4f)__: (CVSS Score 7.1, High): HTTP/1.1: multiple issues with `envoy.reloadable_features.http1_balsa_delay_reset`.

## Am I Impacted?

You are impacted if you are using Istio 1.22.0 to 1.22.6, 1.23.0 to 1.23.3, or 1.24 to 1.24.1, please upgrade immediately. If you have created a custom `EnvoyFilter` to enable the Overload manager, avoid using the `http1_server_abort_dispatch` load shed point.

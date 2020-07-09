---
title: ISTIO-SECURITY-2020-008
subtitle: Security Bulletin
description: Incorrect validation of wildcard DNS Subject Alternative Names.
cves: [CVE-2020-15104]
cvss: "6.6"
vector: "AV:N/AC:H/PR:H/UI:N/S:C/C:H/I:L/A:N/E:F/RL:O/RC:C"
releases: ["1.5 to 1.5.7", "1.6 to 1.6.4", "All releases prior to 1.5"]
publishdate: 2020-07-09
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Istio is vulnerable to a newly discovered vulnerability:

* __[`CVE-2020-15104`](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-15104)__:
When validating TLS certificates, Envoy incorrectly allows a wildcard DNS Subject Alternative Name apply to multiple subdomains. For example, with a SAN of `*.example.com`, Envoy incorrectly allows `nested.subdomain.example.com`, when it should only allow `subdomain.example.com`.
    * CVSS Score: 6.6 [AV:N/AC:H/PR:H/UI:N/S:C/C:H/I:L/A:N/E:F/RL:O/RC:C](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:H/PR:H/UI:N/S:C/C:H/I:L/A:N/E:F/RL:O/RC:C&version=3.1)

Istio users are exposed to this vulnerability in the following ways:

* Direct use of Envoy's `verify_subject_alt_name` and `match_subject_alt_names` configuration via [Envoy Filter](/docs/reference/config/networking/envoy-filter/).

* Use of Istio's [`subjectAltNames` field in destination rules with client TLS settings](/docs/reference/config/networking/destination-rule/#ClientTLSSettings).  A destination rule with a `subjectAltNames` field containing `nested.subdomain.example.com` incorrectly accepts a certificate from an upstream peer with a Subject Alternative Name (SAN) of `*.example.com`.  Instead a SAN of `*.subdomain.example.com` or `nested.subdomain.example.com` should be present.

* Use of Istio's [`subjectAltNames` in service entries](/docs/reference/config/networking/service-entry/).  A service entry with a `subjectAltNames` field with a value similar to `nested.subdomain.example.com` incorrectly accepts a certificate from an upstream peer with a SAN of `*.example.com`.

The Istio CA, which was formerly known as Citadel, does not issue certificates with DNS wildcard SANs. The vulnerability only impacts configurations that validate externally issued certificates.

## Mitigation

* For Istio 1.5.x deployments: update to [Istio 1.5.8](/news/releases/1.5.x/announcing-1.5.8) or later.
* For Istio 1.6.x deployments: update to [Istio 1.6.5](/news/releases/1.6.x/announcing-1.6.5) or later.

{{< boilerplate "security-vulnerability" >}}

---
title: ISTIO-SECURITY-2020-002
subtitle: Security Bulletin
description: Mixer policy check bypass caused by improperly accepting certain request headers.
cves: [CVE-2020-8843]
cvss: "7.4"
vector: "AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:H/A:N"
releases: ["1.3 to 1.3.6"]
publishdate: 2020-02-11
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Istio 1.3 to 1.3.6 contain a vulnerability affecting Mixer policy checks.

Note: We regret that the vulnerability was silently fixed in Istio 1.4.0 and Istio 1.3.7.
An [issue was raised](https://github.com/istio/istio/issues/12063) and [fixed](https://github.com/istio/istio/pull/17692) in Istio 1.4.0 as a non-security issue. We reclassified the issue as a vulnerability in Dec 2019.

* __[CVE-2020-8843](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8843)__: Under certain circumstances it is possible to bypass a specifically configured Mixer policy. Istio-proxy accepts `x-istio-attributes` header at ingress that can be used to affect policy decisions when Mixer policy selectively applies to source equal to ingress.
To be vulnerable, Istio must have Mixer Policy enabled and used in the specified way. This feature is disabled by default in Istio 1.3 and 1.4.

## Mitigation

* For Istio 1.3.x deployments: update to [Istio 1.3.7](/zh/news/releases/1.3.x/announcing-1.3.7) or later.

## Credit

The Istio team would like to thank Krishnan Anantheswaran and Eric Zhang of [Splunk](https://www.splunk.com/) for the private bug report.

{{< boilerplate "security-vulnerability" >}}

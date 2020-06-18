---
title: Announcing Istio 1.2.10
linktitle: 1.2.10
subtitle: Patch Release
description: Istio 1.2.10 patch release.
publishdate: 2019-12-10
release: 1.2.10
aliases:
    - /news/announcing-1.2.10
---

This release contains fixes for the security vulnerability described in [our December 10th, 2019 news post](/news/security/istio-security-2019-007). This release note describes what’s different between Istio 1.2.9 and Istio 1.2.10.

{{< relnote >}}

## Security update

- **ISTIO-SECURITY-2019-007** A heap overflow and improper input validation have been discovered in Envoy.

__[CVE-2019-18801](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18801)__: Fix a vulnerability affecting Envoy's processing of large HTTP/2 request headers.  A successful exploitation of this vulnerability could lead to a denial of service, escalation of privileges, or information disclosure.
__[CVE-2019-18802](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18802)__: Fix a vulnerability resulting from whitespace after HTTP/1 header values which could allow an attacker to bypass Istio's policy checks, potentially resulting in information disclosure or escalation of privileges.
__[CVE-2019-18838](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18838)__: Fix a vulnerability resulting from malformed HTTP request missing the "Host" header. An encoder filter that invokes Envoy's route manager APIs that access request's "Host" header will cause a NULL pointer to be dereferenced and result in abnormal termination of the Envoy process.

## Bug fix

- Add support for Citadel to automatically rotate root cert. ([Issue 17059](https://github.com/istio/istio/issues/17059))

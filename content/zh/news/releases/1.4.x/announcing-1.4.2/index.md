---
title: Announcing Istio 1.4.2
linktitle: 1.4.2
subtitle: Patch Release
description: Istio 1.4.2 patch release.
publishdate: 2019-12-10
release: 1.4.2
aliases:
    - /news/announcing-1.4.2
---

This release contains fixes for the security vulnerability described in [our December 10th, 2019 news post](/news/security/istio-security-2019-007). This release note describes what’s different between Istio 1.4.1 and Istio 1.4.2.

{{< relnote >}}

## Security update

- **ISTIO-SECURITY-2019-007** A heap overflow and improper input validation have been discovered in Envoy.

__[CVE-2019-18801](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18801)__: Fix a vulnerability affecting Envoy's processing of large HTTP/2 request headers.  A successful exploitation of this vulnerability could lead to a denial of service, escalation of privileges, or information disclosure.
__[CVE-2019-18802](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18802)__: Fix a vulnerability resulting from whitespace after HTTP/1 header values which could allow an attacker to bypass Istio's policy checks, potentially resulting in information disclosure or escalation of privileges.

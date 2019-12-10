---
title: Announcing Istio 1.3.6
linktitle: 1.3.6
description: Istio 1.3.6 patch release.
publishdate: 2019-12-10
subtitle: Patch Release
release: 1.3.6
aliases:
    - /news/announcing-1.3.6
---

This release contains fixes for the security vulnerability described in [our December 10th, 2019 news post](/news/security/istio-security-2019-007) as well as bug fixes to improve robustness. This release note describes what's different between Istio 1.3.5 and Istio 1.3.6.

{{< relnote >}}

## Security update

- **ISTIO-SECURITY-2019-007** A heap overflow and improper input validation have been discovered in Envoy.

__[CVE-2019-18801](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18801)__: Fix a vulnerability affecting Envoy's processing of large HTTP/2 request headers.  A successful exploitation of this vulnerability could lead to a denial of service, escalation of privileges, or information disclosure.
__[CVE-2019-18802](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18802)__: Fix a vulnerability resulting from whitespace after HTTP/1 header values which could allow an attacker to bypass Istio's policy checks, potentially resulting in information disclosure or escalation of privileges.

## Bug fixes

- **Fixed** an issue where a duplicate listener was generated for a proxy's IP address when using a headless `TCP` service. ([Issue 17748](https://github.com/istio/istio/issues/17748))
- **Fixed** an issue with the `destination_service` label in HTTP related metrics incorrectly falling back to `request.host` which can cause a metric cardinality explosion for ingress traffic. ([Issue 18818](https://github.com/istio/istio/issues/18818))

## Minor enhancements

- **Improved** load-shedding options for Mixer. Added support for a `requests-per-second` threshold for load-shedding enforcement. This allows operators to turn off load-shedding for Mixer in low traffic scenarios.

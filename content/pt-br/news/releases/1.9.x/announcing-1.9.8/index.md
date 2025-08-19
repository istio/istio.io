---
title: Announcing Istio 1.9.8
linktitle: 1.9.8
subtitle: Patch Release
description: Istio 1.9.8 patch release.
publishdate: 2021-08-24
release: 1.9.8
aliases:
    - /news/announcing-1.9.8
---

This release fixes the security vulnerabilities described in our August 24th post, [ISTIO-SECURITY-2021-008](/news/security/istio-security-2021-008) as
well as a few minor bug fixes to improve robustness. This release note describes what’s different between Istio 1.9.7 and 1.9.8.

{{< relnote >}}

## Security update

- __[CVE-2021-39155](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2CVE-2021-39155])__ __([CVE-2021-32779](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32779))__:
  Istio authorization policies incorrectly compare the host header in a case-sensitive manner against RFC 4343 with states it should be case-insensitive. Envoy routes the request hostname in a case-insensitive way which means the authorization policy could be bypassed.
    - __CVSS Score__: 8.3 [CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:L](https://www.first.org/cvss/calculator/3.1#CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:L)

- __[CVE-2021-39156](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2CVE-2021-39156])__:
  Istio contains a remotely exploitable vulnerability where an HTTP request with a fragment (e.g. #Section) in the path may bypass Istio’s URI path based authorization policies.
    - __CVSS Score__: 8.1 [CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N](https://www.first.org/cvss/calculator/3.1#CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N)

### Envoy Security updates

- [CVE-2021-32777](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32777) (CVSS score 8.6, High): Envoy contains a remotely exploitable vulnerability where an HTTP request with multiple value headers may bypass authorization policies when using the `ext_authz` extension.

- [CVE-2021-32778](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32778) (CVSS score 8.6, High): Envoy contains a remotely exploitable vulnerability where an Envoy client opening and then resetting a large number of HTTP/2 requests may lead to excessive CPU consumption.

- [CVE-2021-32781](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32781) (CVSS score 8.6, High): Envoy contains a remotely exploitable vulnerability that affects Envoy's decompressor, json-transcoder or grpc-web extensions or proprietary extensions that modify and increase the size of request or response bodies. Modifying and increasing the size of the body in an Envoy’s extension beyond internal buffer size may lead to Envoy accessing deallocated memory and terminating abnormally.

## Changes

- **Fixed** users adding invalid ciphers to Gateway `cipherSuites`. ([Issue 34084](https://github.com/istio/istio/issues/34084))

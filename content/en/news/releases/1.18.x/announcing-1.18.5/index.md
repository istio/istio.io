---
title: Announcing Istio 1.18.5
linktitle: 1.18.5
subtitle: Patch Release
description: Istio 1.18.5 patch release.
publishdate: 2023-10-11
release: 1.18.5
---

This release fixes the security vulnerabilities described in our Oct 11th post, [`ISTIO-SECURITY-2023-004`](/news/security/istio-security-2023-004).

This release note describes what’s different between Istio 1.18.3 and 1.18.5. Please note that this release supersedes the unpublished 1.18.4 release. 1.18.4 was only published internally and has been skipped so that additional security fixes could be included in this release.

{{< relnote >}}

## Security updates

- __[`CVE-2023-44487`](https://nvd.nist.gov/vuln/detail/CVE-2023-44487)__: (CVSS Score 7.5, High): HTTP/2 denial of service
- __[`CVE-2023-39325`](https://github.com/golang/go/issues/63417)__: (CVSS Score 7.5, High): HTTP/2 denial of service

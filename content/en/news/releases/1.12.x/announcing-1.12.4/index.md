---
title: Announcing Istio 1.12.4
linktitle: 1.12.4
subtitle: Patch Release
description: Istio 1.12.4 patch release.
publishdate: 2022-02-22
release: 1.12.4
aliases:
    - /news/announcing-1.12.4
---

This release fixes the security vulnerabilities described in our February 22nd post, [ISTIO-SECURITY-2022-003](/news/security/istio-security-2022-003). This release note describes what’s different between Istio 1.12.3 and 1.12.4.

{{< relnote >}}

## Security update

- __[CVE-2022-23635](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2022-23635])__:
  CVE-2022-23635 (CVSS Score 7.5, High):  Unauthenticated control plane denial of service attack.

# Changes

- **Fixed** an issue where service update does not trigger route update.
  ([Issue #37356](https://github.com/istio/istio/pull/37356))

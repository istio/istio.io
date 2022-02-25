---
title: Announcing Istio 1.13.1
linktitle: 1.13.1
subtitle: Patch Release
description: Istio 1.13.1 patch release.
publishdate: 2022-02-22
release: 1.13.1
aliases:
    - /news/announcing-1.13.1
---

This release fixes the security vulnerabilities described in our February 22nd post, [ISTIO-SECURITY-2022-003](/news/security/istio-security-2022-003). This release note describes what’s different between Istio 1.13.0 and 1.13.1.

{{< relnote >}}

## Security update

- __[CVE-2022-23635](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2022-23635])__:
  CVE-2022-23635 (CVSS Score 7.5, High):  Unauthenticated control plane denial of service attack.

# Changes

- **Fixed** `istioctl x describe svc` not evaluating port `appProtocol` properly.
  ([Issue #37159](https://github.com/istio/istio/issues/37159))

- **Fixed** an issue where service update does not trigger route update.
  ([Issue #37356](https://github.com/istio/istio/pull/37356))

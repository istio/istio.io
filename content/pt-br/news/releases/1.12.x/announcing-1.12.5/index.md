---
title: Announcing Istio 1.12.5
linktitle: 1.12.5
subtitle: Patch Release
description: Istio 1.12.5 patch release.
publishdate: 2022-03-09
release: 1.12.5
aliases:
    - /news/announcing-1.12.5
---

This release fixes the security vulnerabilities described in our March 9th post, [ISTIO-SECURITY-2022-004](/news/security/istio-security-2022-004).
This release note describes what’s different between Istio 1.12.4 and 1.12.5.

{{< relnote >}}

## Security update

- __[CVE-2022-24726](https://github.com/istio/istio/security/advisories/GHSA-8w5h-qr4r-2h6g)__:
  (CVSS Score 7.5, High): Unauthenticated control plane denial of service attack due to stack exhaustion.

## Changes

- **Fixed** an issue with Delta CDS where a removed service port would persist after being updated.
  ([Pull Request #37454](https://github.com/istio/istio/pull/37454))

- **Fixed** an issue where CNI ignored traffic annotations.
  ([Issue #37637](https://github.com/istio/istio/issues/37637))

- **Fixed** a bug where cache entries were never updated.
  ([Pull Request #37578](https://github.com/istio/istio/pull/37578))

### Envoy CVEs

At this time it is not believed that Istio is vulnerable to these CVEs in Envoy. They are listed, however,
to be transparent.

- __[CVE-2022-21656](https://github.com/envoyproxy/envoy/security/advisories/GHSA-c9g7-xwcv-pjx2)__
  (CVSS Score 3.1, Low):X.509 `subjectAltName` matching (and `nameConstraints`) bypass.

- __[CVE-2022-21657](https://github.com/envoyproxy/envoy/security/advisories/GHSA-837m-wjrv-vm5g)__
  (CVSS Score 3.1, Low): X.509 Extended Key Usage and Trust Purposes bypass.

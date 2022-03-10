---
title: Announcing Istio 1.11.8
linktitle: 1.11.8
subtitle: Patch Release
description: Istio 1.11.8 patch release.
publishdate: 2022-03-09
release: 1.11.8
aliases:
    - /news/announcing-1.11.8
---

This release fixes the security vulnerabilities described in our March 9th post, [ISTIO-SECURITY-2022-004](/news/security/istio-security-2022-004).
This release note describes what’s different between Istio 1.11.7 and 1.11.8.

{{< relnote >}}

## Security update

- __[CVE-2022-24726](https://github.com/istio/istio/security/advisories/GHSA-8w5h-qr4r-2h6g)__:
  (CVSS Score 7.5, High): Unauthenticated control plane denial of service attack due to stack exhaustion.

### Envoy CVEs

At this time it is not believed that Istio is vulnerable to these CVEs in Envoy. They are listed, however,
to be transparent.

- __[CVE-2022-21657](https://github.com/envoyproxy/envoy/security/advisories/GHSA-837m-wjrv-vm5g)__
  (CVSS Score 3.1, Low): X.509 Extended Key Usage and Trust Purposes bypass.

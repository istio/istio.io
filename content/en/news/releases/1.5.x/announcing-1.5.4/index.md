---
title: Announcing Istio 1.5.4
linktitle: 1.5.4
subtitle: Patch Release
description: Istio 1.5.4 security release.
publishdate: 2020-05-13
release: 1.5.4
aliases:
    - /news/announcing-1.5.4
---

This release fixes the security vulnerability described in [our May 12th, 2020 news post](/news/security/istio-security-2020-005).

This release note describes what's different between Istio 1.5.4 and Istio 1.5.3.

{{< relnote >}}

## Security update

- **ISTIO-SECURITY-2020-005** Denial of Service with Telemetry V2 enabled.

__[CVE-2020-10739](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-10739)__: By sending a specially crafted packet, an attacker could trigger a Null Pointer Exception resulting in a Denial of Service. This could be sent to the ingress gateway or a sidecar.

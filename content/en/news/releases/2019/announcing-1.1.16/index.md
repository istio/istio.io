---
title: Announcing Istio 1.1.16
subtitle: Patch Release
description: Istio 1.1.16 patch release.
publishdate: 2019-10-08
release: 1.1.16
aliases:
    - /news/announcing-1.1.16
---

We're pleased to announce the availability of Istio 1.1.16. Please see below for what's changed.

{{< relnote >}}

## Security update

This release contains fixes for the security vulnerability described in [our October 8th, 2019 news post](/news/2019/istio-security-2019-005).  Specifically:

__ISTIO-SECURITY-2019-005__:  A DoS vulnerability has been discovered by the Envoy community.
  * __[CVE-2019-15226](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-15226)__: After investigation, the Istio team has found that this issue could be leveraged for a DoS attack in Istio if an attacker uses a high quantity of very small headers.

Nothing else is included in this release except for the above security fix.

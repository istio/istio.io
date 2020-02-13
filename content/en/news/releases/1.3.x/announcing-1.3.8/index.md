---
title: Announcing Istio 1.3.8
linktitle: 1.3.8
subtitle: Patch Release
description: Istio 1.3.8 patch release.
publishdate: 2020-02-11
release: 1.3.8
aliases:
    - /news/announcing-1.3.8
---

This release contains a fix for the security vulnerability described in [our February 11th, 2020 news post](/news/security/istio-security-2020-001). This release note describes what's different between Istio 1.3.7 and Istio 1.3.8.

{{< relnote >}}

## Security update

- **ISTIO-SECURITY-2020-001** Improper input validation have been discovered in `AuthenticationPolicy`.

__[CVE-2020-8595](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8595)__: A bug in Istio's [Authentication Policy](/docs/reference/config/security/istio.authentication.v1alpha1/#Policy) exact path matching logic allows unauthorized access to resources without a valid JWT token.

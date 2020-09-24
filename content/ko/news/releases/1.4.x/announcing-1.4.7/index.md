---
title: Announcing Istio 1.4.7
linktitle: 1.4.7
subtitle: Patch Release
description: Istio 1.4.7 patch release.
publishdate: 2020-03-25
release: 1.4.7
aliases:
    - /news/announcing-1.4.7
---

This release contains fixes for the security vulnerabilities described in [our March 25th, 2020 news post](/news/security/istio-security-2020-004). This release note describes what’s different between Istio 1.4.6 and Istio 1.4.7.

{{< relnote >}}

## Security Update

- **ISTIO-SECURITY-2020-004** Istio uses a hard coded `signing_key` for Kiali.

__[CVE-2020-1764](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-1764)__: Istio uses a default `signing key` to install Kiali. This can allow an attacker with access to Kiali to bypass authentication and gain administrative privileges over Istio.
In addition, another CVE is fixed in this release, described in the Kiali 1.15.1 [release](https://kiali.io/news/security-bulletins/kiali-security-001/).

## Changes

- **Fixed** an issue causing protocol detection to break HTTP2 traffic to gateways ([Issue 21230](https://github.com/istio/istio/issues/21230)).

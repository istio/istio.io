---
title: Announcing Istio 1.9.6
linktitle: 1.9.6
subtitle: Patch Release
description: Istio 1.9.6 patch release.
publishdate: 2021-06-24
release: 1.9.6
aliases:
    - /news/announcing-1.9.6
---

This release fixes the security vulnerabilities described in our June 24th post, [ISTIO-SECURITY-2021-007](/news/security/istio-security-2021-007) as
well as a few minor bug fixes to improve robustness. This release note describes what’s different between Istio 1.9.5 and Istio 1.9.6.

{{< relnote >}}

## Security update

- __[CVE-2021-34824](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-34824)__:
Istio contains a remotely exploitable vulnerability where credentials specified in the `Gateway` and `DestinationRule` `credentialName` field can be accessed from different namespaces. See the [ISTIO-SECURITY-2021-007 bulletin](/news/security/istio-security-2021-007) for more details.
    - __CVSS Score__: 9.1 [CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:L/A:L](https://www.first.org/cvss/calculator/3.1#CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:L/A:L)

## Changes

- **Fixed** an issue where IPv6 iptables rules were incorrect when the `traffic.sidecar.istio.io/includeOutboundPorts` annotation was used.
 ([Issue #30868](https://github.com/istio/istio/issues/30868))

- **Fixed** an issue causing Envoy Filters that merge the `transport_socket` field and have a custom transport socket name to be ignored.

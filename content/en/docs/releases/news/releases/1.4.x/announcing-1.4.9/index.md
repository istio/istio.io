---
title: Announcing Istio 1.4.9
linktitle: 1.4.9
subtitle: Patch Release
description: Istio 1.4.9 patch release.
publishdate: 2020-05-12
release: 1.4.9
aliases:
    - /news/announcing-1.4.9
---

This release contains bug fixes to improve robustness and fixes for the security vulnerabilities described in [our May 12th, 2020 news post](/news/security/istio-security-2020-005). This release note describes what's different between Istio 1.4.9 and Istio 1.4.8.

{{< relnote >}}

## Security update

- **ISTIO-SECURITY-2020-005** Denial of Service with Telemetry V2 enabled.

__[CVE-2020-10739](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-10739)__: By sending a specially crafted packet, an attacker could trigger a Null Pointer Exception resulting in a Denial of Service. This could be sent to the ingress gateway or a sidecar.

## Bug Fixes

- **Fixed** the Helm installer to install Kiali using an dynamically generated signing key.
- **Fixed** Citadel to ignore namespaces that are not part of the mesh.
- **Fixed** the Istio operator installer to print the name of any resources that are not ready when an installation timeout occurs.

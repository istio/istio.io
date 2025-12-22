---
title: Announcing Istio 1.26.8
linktitle: 1.26.8
subtitle: Patch Release
description: Istio 1.26.8 patch release.
publishdate: 2025-12-22
release: 1.26.8
aliases:
    - /news/announcing-1.26.8
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.26.7 and 1.26.8.

{{< relnote >}}

## Security Update

- [CVE-2025-62408](https://github.com/envoyproxy/envoy/security/advisories/GHSA-fg9g-pvc4-776f) (CVSS score 5.3, Moderate): Use after free can crash Envoy due to malfunctioning or compromised DNS. This is a heap use-after-free vulnerability in the c-ares library that can be exploited by an attacker controlling the local DNS infrastructure to cause a Denial of Service (DoS) in Envoy.

## Changes

- **Fixed** an issue where HTTPS servers processed first prevented HTTP servers from creating routes on the same port with different bind addresses.  ([Issue #57706](https://github.com/istio/istio/issues/57706))

---
title: Announcing Istio 1.27.5
linktitle: 1.27.5
subtitle: Patch Release
description: Istio 1.27.5 patch release.
publishdate: 2025-12-22
release: 1.27.5
aliases:
    - /news/announcing-1.27.5
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.27.4 and 1.27.5.

{{< relnote >}}

## Security Update

- [CVE-2025-62408](https://github.com/envoyproxy/envoy/security/advisories/GHSA-fg9g-pvc4-776f) (CVSS Score 5.3, Medium): Use after free can crash Envoy due to malfunctioning or compromised DNS.

## Changes

- **Fixed** DNS name table creation for headless services where pods entries did not account for pods to have multiple IPs.  ([Issue #58397](https://github.com/istio/istio/issues/58397))

---
title: Announcing Istio 1.22.3
linktitle: 1.22.3
subtitle: Patch Release
description: Istio 1.22.3 patch release.
publishdate: 2024-07-15
release: 1.22.3
---

This release note describes what is different between Istio 1.22.2 and 1.22.3.

{{< relnote >}}

## Changes

- **Updated** Go version to include security fixes for the net/http package related to [`CVE-2024-24791`](https://github.com/advisories/GHSA-hw49-2p59-3mhj)

- **Updated** Envoy version to include security fixes related to [`CVE-2024-39305`](https://github.com/envoyproxy/envoy/security/advisories/GHSA-fp35-g349-h66f)

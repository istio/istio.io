---
title: Announcing Istio 1.22.3
linktitle: 1.22.3
subtitle: Patch Release
description: Istio 1.22.3 patch release.
publishdate: 2024-07-16
release: 1.22.3
---

This release note describes what is different between Istio 1.22.2 and 1.22.3.

{{< relnote >}}

## Changes

- **Updated** Go version to include security fixes for the net/http package related to [`CVE-2024-24791`](https://github.com/advisories/GHSA-hw49-2p59-3mhj)

- **Updated** Envoy version to include security fixes related to [`CVE-2024-39305`](https://github.com/envoyproxy/envoy/security/advisories/GHSA-fp35-g349-h66f)

- **Fixed** a bug where router's merged gateway was not immediately recomputed when a service was created or updated. ([Issue #51726](https://github.com/istio/istio/issues/51726))

- **Fixed** inconsistent behavior with the `istio_agent_cert_expiry_seconds` metric.

- **Removed** sorting of JSON access logs pending [Envoy fix](https://github.com/envoyproxy/envoy/issues/34420).

---
title: Announcing Istio 1.20.8
linktitle: 1.20.8
subtitle: Patch Release
description: Istio 1.20.8 patch release.
publishdate: 2024-07-01
release: 1.20.8
---

This release note describes what’s different between Istio 1.20.7 and 1.20.8.

{{< relnote >}}

## Changes

- **Added** `gateways.securityContext` to manifests to provide an option to customize the gateway `securityContext`.
  ([Issue #49549](https://github.com/istio/istio/issues/49549))

- **Fixed** an issue where JWKS fetched from URIs were not updated promptly when there are errors fetching other URIs.
  ([Issue #51636](https://github.com/istio/istio/issues/51636))

- **Fixed** 503 errors returned by `auto-passthrough` gateways created after enabling mTLS.

- **Fixed** `serviceRegistry` ordering of the proxy labels, so we put the Kubernetes registry in front.
  ([Issue #50968](https://github.com/istio/istio/issues/50968))

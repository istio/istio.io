---
title: Announcing Istio 1.20.8
linktitle: 1.20.8
subtitle: Patch Release
description: Istio 1.20.8 patch release.
publishdate: 2024-06-28
release: 1.20.8
---

This release note describes what’s different between Istio 1.20.7 and 1.20.8.

{{< relnote >}}

# Changes

- **Added** manifests: add `gateways.securityContext` option to custom gateway securityContext.
  ([Issue #49549](https://github.com/istio/istio/issues/49549))

- **Fixed** JWKS fetched from URIs may not be updated promptly when there are errors fetching other URIs
  ([Issue #51636](https://github.com/istio/istio/issues/51636))

- **Fixed** returning 503 errors by auto-passthrough gateways created after enabling mTLS.

- **Fixed** serviceRegistry orders influence the proxy labels, so we put the kubernetes registry in front.
  ([Issue #50968](https://github.com/istio/istio/issues/50968))

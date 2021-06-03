---
title: Announcing Istio 1.6.12
linktitle: 1.6.12
subtitle: Patch Release
description: Istio 1.6.12 patch release.
publishdate: 2020-10-06
release: 1.6.12
aliases:
    - /news/announcing-1.6.12
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.6.11 and Istio 1.6.12

{{< relnote >}}

## Changes

- **Added** ability to configure domain suffix for multicluster installation ([Issue #27300](https://github.com/istio/istio/issues/27300))

- **Added** support for `securityContext` in the Kubernetes settings for the operator API. ([Issue #26275](https://github.com/istio/istio/issues/26275))

- **Fixed** an issue preventing calls to wildcard (such as `*.example.com`) domains when a port is set in the `Host` header. ([Issue #25350](https://github.com/istio/istio/issues/25350))

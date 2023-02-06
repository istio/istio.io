---
title: Announcing Istio 1.15.5
linktitle: 1.15.5
subtitle: Patch Release
description: Istio 1.15.5 patch release.
publishdate: 2023-01-30
release: 1.15.5
aliases:
    - /news/announcing-1.15.5
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.15.4 and Istio 1.15.5.

{{< relnote >}}

## Changes

- **Added** the `--revision` flag to `istioctl analyze` making it possible to specify a revision.
  ([Issue #38148](https://github.com/istio/istio/issues/38148))

- **Added** mitigation for a request smuggling vulnerability caused by an issue in the Go http2 library. ([Issue #56352](https://github.com/golang/go/issues/56352))

- **Fixed** a bug causing the abnormal exit of istiod when DestinationRule `PortLevelSettings[].Port` was nil. ([Issue #42598](https://github.com/istio/istio/issues/42598))

- **Fixed** a bug causing namespace level network labels (`topology.istio.io/network`) to take precedence over pod labels. ([Issue #42675](https://github.com/istio/istio/issues/42675))

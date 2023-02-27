---
title: Announcing Istio 1.7.8
linktitle: 1.7.8
subtitle: Patch Release
description: Istio 1.7.8 patch release.
publishdate: 2021-02-25
release: 1.7.8
aliases:
- /news/announcing-1.7.8
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.7.7 and Istio 1.7.8

{{< relnote >}}

## Changes

- **Fixed** an issue where dashboard `controlz` would not port forward to istiod pod.
  ([Issue #30208](https://github.com/istio/istio/issues/30208))
- **Fixed** an issue where namespace isn’t resolved correctly in `VirtualService` delegation’s short destination host.
  ([Issue #30387](https://github.com/istio/istio/issues/30387))
- **Fixed** an issue causing HTTP headers to be duplicated when using Istio probe rewrite.
  ([Issue #28466](https://github.com/istio/istio/issues/28466))

---
title: Announcing Istio 1.13.4
linktitle: 1.13.4
subtitle: Patch Release
description: Istio 1.13.4 patch release.
publishdate: 2022-05-17
release: 1.13.4
aliases:
    - /news/announcing-1.13.4
---

This release contains bug fixes to improve robustness.
This release note describes what's different between Istio 1.13.3 and 1.13.4.

{{< relnote >}}

## Changes

- **Fixed** some `ServiceEntry` hostnames causing non-deterministic Envoy routes.
  ([Issue #38678](https://github.com/istio/istio/issues/38678))

- **Fixed** `istioctl experimental describe pod` error: `failed to fetch mesh config`.
  ([Issue #38636](https://github.com/istio/istio/issues/38636))

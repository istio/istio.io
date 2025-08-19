---
title: Announcing Istio 1.12.7
linktitle: 1.12.7
subtitle: Patch Release
description: Istio 1.12.7 patch release.
publishdate: 2022-05-06
release: 1.12.7
aliases:
    - /news/announcing-1.12.7
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.12.6 and Istio 1.12.7

{{< relnote >}}

## Changes

- **Added** support for skipping the initial installation of CNI entirely.
  ([Pull Request #38158](https://github.com/istio/istio/pull/38158))

- **Fixed** the in-cluster operator unable to prune resources when the Istio control plane has active proxies connected.
  ([Issue #35657](https://github.com/istio/istio/issues/35657))

- **Fixed** an issue in webhook analysis which would make helm reconciler complain about overlapping webhooks.
  ([Issue #36114](https://github.com/istio/istio/issues/36114))

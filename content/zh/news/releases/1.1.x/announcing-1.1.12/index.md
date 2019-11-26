---
title: Announcing Istio 1.1.12
linktitle: 1.1.12
subtitle: Patch Release
description: Istio 1.1.12 patch release.
publishdate: 2019-08-02
release: 1.1.12
aliases:
    - /zh/about/notes/1.1.12
    - /zh/blog/2019/announcing-1.1.12
    - /zh/news/2019/announcing-1.1.12
    - /zh/news/announcing-1.1.12
---

We're pleased to announce the availability of Istio 1.1.12. Please see below for what's changed.

{{< relnote >}}

## Bug fixes

- Fix a bug where the sidecar could infinitely forward requests to itself when a `Pod` resource defines a port that isn't defined for a service ([Issue 14443](https://github.com/istio/istio/issues/14443)) and ([Issue 14242](https://github.com/istio/istio/issues/14242))

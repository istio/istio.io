---
title: Announcing Istio 1.2.2
linktitle: 1.2.2
subtitle: Patch Release
description: Istio 1.2.2 patch release.
publishdate: 2019-06-28
release: 1.2.2
aliases:
    - /zh/about/notes/1.2.2
    - /zh/blog/2019/announcing-1.2.2
    - /zh/news/2019/announcing-1.2.2
    - /zh/news/announcing-1.2.2
---

We're pleased to announce the availability of Istio 1.2.2. Please see below for what's changed.

{{< relnote >}}

## Bug fixes

- Fix crash in Istio's JWT Envoy filter caused by malformed JWT ([Issue 15084](https://github.com/istio/istio/issues/15084))
- Fix incorrect overwrite of x-forwarded-proto header ([Issue 15124](https://github.com/istio/istio/issues/15124))

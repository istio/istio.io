---
title: Announcing Istio 1.2.2
description: Istio 1.2.2 patch release.
publishdate: 2019-06-28
attribution: The Istio Team
release: 1.2.2
aliases:
    - /about/notes/1.2.2
    - /blog/2019/announcing-1.2.2
    - /news/announcing-1.2.2
---

We're pleased to announce the availability of Istio 1.2.2. Please see below for what's changed.

{{< relnote >}}

## Bug fixes

- Fix crash in Istio's JWT Envoy filter caused by malformed JWT ([Issue 15084](https://github.com/istio/istio/issues/15084))
- Fix incorrect overwrite of x-forwarded-proto header ([Issue 15124](https://github.com/istio/istio/issues/15124))

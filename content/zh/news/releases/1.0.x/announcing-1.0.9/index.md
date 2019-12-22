---
title: Announcing Istio 1.0.9
linktitle: 1.0.9
subtitle: Patch Release
description: Istio 1.0.9 patch release.
publishdate: 2019-06-28
release: 1.0.9
aliases:
    - /zh/about/notes/1.0.9
    - /zh/blog/2019/announcing-1.0.9
    - /zh/news/2019/announcing-1.0.9
    - /zh/news/announcing-1.0.9
---

我们很高兴的宣布 Istio 1.0.9 现已正式发布。下面是更新详情。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- 修复了由格式错误的 JWT 导致 Istio JWT Envoy 过滤器崩溃的问题（[Issue 15084](https://github.com/istio/istio/issues/15084)）。

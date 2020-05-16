---
title: Istio 1.2.2 发布公告
linktitle: 1.2.2
subtitle: 补丁发布
description: Istio 1.2.2 补丁发布。
publishdate: 2019-06-28
release: 1.2.2
aliases:
    - /zh/about/notes/1.2.2
    - /zh/blog/2019/announcing-1.2.2
    - /zh/news/2019/announcing-1.2.2
    - /zh/news/announcing-1.2.2
---

我们很高兴的宣布 Istio 1.2.2 现在是可用的，具体更新内容如下。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- 修复由 JWT 格式错误导致的 Istio JWT Envoy 过滤器崩溃（[Issue 15084](https://github.com/istio/istio/issues/15084)）
- 修复 x-forward-proto header 的错误覆盖（[Issue 15124](https://github.com/istio/istio/issues/15124)）

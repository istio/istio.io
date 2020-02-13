---
title: Istio 1.1.12 发布公告
linktitle: 1.1.12
subtitle: 补丁发布
description: Istio 1.1.12 补丁发布。
publishdate: 2019-08-02
release: 1.1.12
aliases:
    - /zh/about/notes/1.1.12
    - /zh/blog/2019/announcing-1.1.12
    - /zh/news/2019/announcing-1.1.12
    - /zh/news/announcing-1.1.12
---

我们非常高兴的宣布 Istio 1.1.12 已经可用。请浏览下面的变更说明。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- 修复了一个错误，当 `Pod` 资源定义了一个端口，但 service 中未定义时，sidecar 可以将请求无限转发给自己（[Issue 14443](https://github.com/istio/istio/issues/14443)）和（[Issue 14242](https://github.com/istio/istio/issues/14242)）

---
title: Istio 1.1.17 发布公告
linktitle: 1.1.17
subtitle: 补丁发布
description: Istio 1.1.17 补丁发布。
publishdate: 2019-10-21
release: 1.1.17
aliases:
    - /zh/news/2019/announcing-1.1.7
    - /zh/news/announcing-1.1.7
---

我们非常高兴的宣布 Istio 1.1.17 已经可用。这将是最后一个 1.1.x 的补丁版本。请浏览下面的变更说明。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- 修复了一个由 [10 月 8 日安全补丁](/zh/news/security/istio-security-2019-005)引入的 bug，它错误地计算 HTTP 头和请求体大小（[Issue 17735](https://github.com/istio/istio/issues/17735)）。

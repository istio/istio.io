---
title: Istio 1.1.15 发布公告
linktitle: 1.1.15
subtitle: 发布补丁
description: Istio 1.1.15 版本发布公告。
publishdate: 2019-09-16
release: 1.1.15
aliases:
    - /zh/about/notes/1.1.15
    - /zh/blog/2019/announcing-1.1.15
    - /zh/news/2019/announcing-1.1.15
    - /zh/news/announcing-1.1.15
---

我们很高兴地宣布 Istio 1.1.15 现在是可用的，详情请查看如下更改。

{{< relnote >}}

Bug 修复{#bug-fixes}

- 修复 Istio 1.1.14 中引入的 Envoy 崩溃 bug ([Issue 16357](https://github.com/istio/istio/issues/16357))。

## 小改进{#small-enhancements}

- 暴露 `HTTP/2` 窗口大小作为 Pilot 环境变量 ([Issue 17117](https://github.com/istio/istio/issues/17117))。

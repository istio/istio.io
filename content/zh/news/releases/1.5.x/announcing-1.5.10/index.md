---
title: Istio 1.5.10 发布公告
linktitle: 1.5.10
subtitle: 补丁发布
description: Istio 1.5.10 补丁发布。
publishdate: 2020-08-24
release: 1.5.10
aliases:
    - /zh/news/announcing-1.5.10
---

这个版本包括一些 bug 的修复用以提高程序的健壮性。同时这些发布说明也描述了 Istio 1.5.9 和 Istio 1.5.10 之间的区别。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- **修复** 修复了在 telemetry v2 版本中，容器名称为 `app_container` 的问题。
- **修复** 修复了进入 SDS 获取不到密匙更新的问题。 ([Issue 23715](https://github.com/istio/istio/issues/23715)).

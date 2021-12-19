---
title: Istio 1.7.8 发布公告
linktitle: 1.7.8
subtitle: 补丁发布
description: Istio 1.7.8 补丁发布。
publishdate: 2021-02-25
release: 1.7.8
aliases:
- /zh/news/announcing-1.7.8
---

此版本包含一些 bug 的修复用以提高程序的健壮性。同时这个版本说明也描述了 Istio 1.7.7 和 Istio 1.7.8 之间的区别。

{{< relnote >}}

## 改变{#changes}

- **修复** 修复了仪表盘的 `controlz` 不会被转发到 istiod pod 的问题。
  ([Issue #30208](https://github.com/istio/istio/issues/30208))
- **修复** 修复了在委托的 `VirtualService` 中，目标主机的命名空间不能被正确解析的问题。
  ([Issue #30387](https://github.com/istio/istio/issues/30387))
- **修复** 修正了当启用 Istio 探针重写时导致 HTTP 报头重复的问题。
  ([Issue #28466](https://github.com/istio/istio/issues/28466))
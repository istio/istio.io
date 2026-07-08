---
title: 发布 Istio 1.28.10
linktitle: 1.28.10
subtitle: 补丁发布
description: Istio 1.28.10 补丁发布。
publishdate: 2026-07-01
release: 1.28.10
aliases:
    - /zh/news/announcing-1.28.10
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.28.9 和 Istio 1.28.10 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了 `krt` 控制器框架中的一个内存泄漏问题，
  当更改 `Fetch` 过滤器中使用的键（例如，重新标记 Pod 以指向不同的 waypoint）时，
  会导致残留的反向索引条目无法被清理。随着时间推移，这可能导致内存占用增加并引发不必要的重新计算。

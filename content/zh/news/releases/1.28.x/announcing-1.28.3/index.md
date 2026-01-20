---
title: 发布 Istio 1.28.3
linktitle: 1.28.3
subtitle: 补丁发布
description: Istio 1.28.3 补丁发布。
publishdate: 2025-01-19
release: 1.28.3
aliases:
    - /zh/news/announcing-1.28.3
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.28.2 和 Istio 1.28.3 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **新增** 添加了网关 Helm Chart 中的 `service.selectorLabels` 字段，
  用于在基于版本修订的迁移过程中自定义服务选择器标签。

- **修复** 修复了 Ambient 模式下 goroutine 内存泄漏的问题。
  ([Issue #58478](https://github.com/istio/istio/issues/58478))

- **修复** 修复了 Ambient 多集群模式下的一个问题，
  该问题导致远程集群的 informer 故障在 Istiod 重启之前无法修复。
  ([Issue #58047](https://github.com/istio/istio/issues/58047))

- **修复** 修复了导致 NFT 操作崩溃和 Pod 删除失败的问题。
  ([Issue #58492](https://github.com/istio/istio/issues/58492))

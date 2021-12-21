---
title: 发布 Istio 1.10.1 版本
linktitle: 1.10.1
subtitle: 补丁发布
description: Istio 1.10.1 补丁发布。
publishdate: 2021-06-09
release: 1.10.1
aliases:
    - /zh/news/announcing-1.10.1
---

此版本包含一些漏洞修复，从而提高了系统的稳健性。这个版本说明描述了 Istio 1.10.0 和 Istio 1.10.1 之间的区别。

{{< relnote >}}

## 改变{#changes}

- **修复** 修复了导致 `Host` 数据包报头无法在 `VirtualService` 中针对特定通信目的端进行修改的问题。 ([Issue #33226](https://github.com/istio/istio/issues/33226))

- **修复** 修复了无法在 `IstioOperator` 中设置 PDB 的 `maxUnavailable` 字段的问题。 ([Issue #31910](https://github.com/istio/istio/issues/31910))

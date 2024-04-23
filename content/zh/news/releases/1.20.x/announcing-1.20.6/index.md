---
title: 发布 Istio 1.20.6
linktitle: 1.20.6
subtitle: 补丁发布
description: Istio 1.20.6 补丁发布。
publishdate: 2024-04-22
release: 1.20.6
---

本次发布实现了 4 月 22 日公布的安全更新 [`ISTIO-SECURITY-2024-003`](/zh/news/security/istio-security-2024-003)
并修复了一些错误，提高了稳健性。

本发布说明描述了 Istio 1.20.5 和 Istio 1.20.6 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **新增** 添加了 `pprof` 端点来对 CNI Pod（在 9867 端口上）进行分析。
  ([Issue #49053](https://github.com/istio/istio/issues/49053))

- **改进** 改进了 CNI 内存使用，避免将大文件保留在内存中。
  ([Issue #49053](https://github.com/istio/istio/issues/49053))

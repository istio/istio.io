---
title: Istio 1.12.6 发布说明
linktitle: 1.12.6
subtitle: Patch Release
description: Istio 1.12.6 补丁发布。
publishdate: 2022-04-06
release: 1.12.6
aliases:
    - /zh/news/announcing-1.12.6
---

此版本修复了一些漏洞以增强健壮性。此发布说明描述了 Istio 1.12.5 和 1.12.6 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了 1.12 中执行 `istioctl upgrade` 会造成 webhook 重叠的错误。
  ([Issue #37908](https://github.com/istio/istio/issues/37908))

- **修复** 修复了通过 Telemetry API 禁用存取日志记录后仍然记录 TCP 调用的问题。

- **修复** 修复了升级到 Istio 1.12+ 后一些跨命名空间的 `VirtualServices` 被错误忽略的问题。
  ([Issue #37691](https://github.com/istio/istio/issues/37691))

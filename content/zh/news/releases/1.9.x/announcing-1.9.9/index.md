---
title: 发布 Istio 1.9.9 版本
linktitle: 1.9.9
subtitle: 补丁发布
description: Istio 1.9.9 补丁发布。
publishdate: 2021-10-08
release: 1.9.9
aliases:
    - /zh/news/announcing-1.9.9
---

这是 Istio 1.9 的最终版本。我们建议您升级到最新的 Istio 支持版本，Istio ({{<istio_release_name>}})。

此版本包含一些错误修复以提高稳健性。 这个版本说明描述 Istio 1.9.8 和 Istio 1.9.9 之间的区别。

{{< relnote >}}

## 变化

- **修复** 根据 [RFC 6750](https://datatracker.ietf.org/doc/html/rfc6750#section-3) 规范，JWT 未经授权的响应现在包括一个 `www-authenticate` 头。
- **修复** 代理断开连接后，Istiod 内存泄漏。
- **修复** `DestinationRule` 更新不会触发网关上 `AUTO_PASSTHROUGH` 监听器的更新。

---
title: 发布 Istio 1.18.7
linktitle: 1.18.7
subtitle: 补丁发布
description: Istio 1.18.7 补丁发布。
publishdate: 2024-01-04
release: 1.18.7
---

该版本包含的错误修复用于提高稳健性。

本发布说明描述了 Istio 1.18.6 和 Istio 1.18.7 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了一个当选择通配符服务时（例如在 `ServiceEntry` 中），
  `VirtualService` 中重叠的通配符主机会产生不正确的路由配置的错误。
  ([Issue #45415](https://github.com/istio/istio/issues/45415))

- **修复** 修复了 `istioctl proxy-config ecds` 未显示所有 `EcdsConfigDump` 的问题。

- **修复** 修复了新端点可能无法被发送到代理的问题。
  ([Issue #48373](https://github.com/istio/istio/issues/48373))

- **修复** 修复了使用 Stackdriver 安装并使用自定义配置会阻止 Stackdriver 被启用的问题。

- **修复** 修复了长连接、TCP 字节和 gRPC 可能导致代理内存泄漏的问题。

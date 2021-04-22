---
title: 发布 Istio 1.8.1 版本
linktitle: 1.8.1
subtitle: 补丁发布
description: Istio 1.8.1 补丁发布。
publishdate: 2020-12-08
release: 1.8.1
aliases:
    - /zh/news/announcing-1.8.1
---

这个版本包含了错误修复，以提高稳定性。主要说明 Istio 1.8.0 和 Istio 1.8.1 之间的不同之处。

{{< relnote >}}

## 变动{#changes}

- **修复** 当将 Istio 降级到低版本时，显示不必要的警告的问题。
  ([Issue #29183](https://github.com/istio/istio/issues/29183))

- **修复** Delegate `VirtualService` 的变化不会触发 xDS 推送的问题。
  ([Issue #29123](https://github.com/istio/istio/issues/29123))

- **修复** Istio 1.8.0 中的一个回归，导致具有多个服务且端口重叠的工作负载将流量发送到错误的端口。
  ([Issue #29199](https://github.com/istio/istio/issues/29199))

- **修复** 导致 Istio 尝试验证不再支持的资源类型的错误。

---
title: 发布 Istio 1.20.8
linktitle: 1.20.8
subtitle: 补丁发布
description: Istio 1.20.8 补丁发布。
publishdate: 2024-07-01
release: 1.20.8
---

本发布说明描述了 Istio 1.20.7 和 Istio 1.20.8 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **新增** 添加了 `gateways.securityContext` 到清单中，以提供自定义网关 `securityContext` 的选项。
  ([Issue #49549](https://github.com/istio/istio/issues/49549))

- **修复** 修复了当获取其他 URI 时出现错误时，从 URI 获取的 JWKS 未及时更新的问题。
  ([Issue #51636](https://github.com/istio/istio/issues/51636))

- **修复** 修复了启用 mTLS 后创建的 `auto-passthrough` 网关返回的 503 错误。

- **修复** 修复了代理标签的 `serviceRegistry` 排序，因此我们将 Kubernetes 注册表放在前面。
  ([Issue #50968](https://github.com/istio/istio/issues/50968))

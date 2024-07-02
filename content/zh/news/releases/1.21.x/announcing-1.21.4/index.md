---
title: 发布 Istio 1.21.4
linktitle: 1.21.4
subtitle: 补丁发布
description: Istio 1.21.4 补丁发布。
publishdate: 2024-06-27
release: 1.21.4
---

本次发布实现了 6 月 27 日公布的安全更新 [`ISTIO-SECURITY-2024-005`](/zh/news/security/istio-security-2024-005)
并修复了一些错误，提高了稳健性。

本发布说明描述了 Istio 1.21.3 和 Istio 1.21.4 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **新增** 添加了 `gateways.securityContext` 到清单中，以提供自定义网关 `securityContext` 的选项。
  ([Issue #49549](https://github.com/istio/istio/issues/49549))

- **修复** 修复了 `istioctl analyze` 返回 IST0162 误报的问题。
  ([Issue #51257](https://github.com/istio/istio/issues/51257))

- **修复** 当设置 `credentialName` 和 `workloadSelector` 时，修复了 IST0128 和 IST0129 中的误报问题。
  ([Issue #51567](https://github.com/istio/istio/issues/51567))

- **修复** 修复了当获取其他 URI 时出现错误时，从 URI 获取的 JWKS 未及时更新的问题。
  ([Issue #51636](https://github.com/istio/istio/issues/51636))

- **修复** 修复了启用 mTLS 后创建的 `auto-passthrough` 网关返回的 503 错误。

- **修复** 修复了代理标签的 `serviceRegistry` 排序，因此我们将 Kubernetes 注册表放在前面。
  ([Issue #50968](https://github.com/istio/istio/issues/50968))

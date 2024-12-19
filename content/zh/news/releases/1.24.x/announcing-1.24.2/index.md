---
title: 发布 Istio 1.24.2
linktitle: 1.24.2
subtitle: 补丁发布
description: Istio 1.24.2 补丁发布。
publishdate: 2024-12-18
release: 1.24.2
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.24.1 和 Istio 1.24.2 之间的区别。

本次发布实现了 12 月 18 日公布的安全更新
[`ISTIO-SECURITY-2024-007`](/zh/news/security/istio-security-2024-007)。

{{< relnote >}}

## 变更 {#changes}

- **新增** 向 `istio-cni-node` DaemonSet 添加 `DAC_OVERRIDE` 功能。
  这解决了在某些文件由非 root 用户拥有的环境中运行时出现的问题。
  注意：在 Istio 1.24 之前，`istio-cni-node` 以 `privileged` 身份运行。
  Istio 1.24 删除了此功能，但删除了一些必需的权限，现在已重新添加。
  相对于 Istio 1.23，`istio-cni-node` 的权限仍然比此更改后的权限少。

- **修复** 修复了 Helm 渲染问题，以便在 Pilot 的 `ServiceAccount` 上正确应用注解。
  ([Issue #51289](https://github.com/istio/istio/issues/51289))

- **修复** 修复了 `istiod` 无法正确处理跨命名空间航点代理的 `RequestAuthentication` 的问题。
  ([Issue #54051](https://github.com/istio/istio/issues/54051))

- **修复** 修复了非默认修订控制网关缺少 `istio.io/rev` 标签的问题。
  ([Issue #54280](https://github.com/istio/istio/issues/54280))

- **修复** 修复了使用 Ambient 模式和 DNS 代理时 `ExternalName` 服务无法解析的问题。

- **修复** 修复了阻止配置 `PodDisruptionBudget` `maxUnavailable` 字段的问题。
  ([Issue #54087](https://github.com/istio/istio/issues/54087))

- **修复** 修复了当 Sidecar 注入器无法处理 Sidecar 配置时，
  注入配置错误被忽略（即记录但未返回）的问题。
  此更改现在会将错误传播给用户，而不是继续处理错误的配置。
  ([Issue #53357](https://github.com/istio/istio/issues/53357))

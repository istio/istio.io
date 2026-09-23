---
title: 发布 Istio 1.23.4
linktitle: 1.23.4
subtitle: 补丁发布
description: Istio 1.23.4 补丁发布。
publishdate: 2024-12-18
release: 1.23.4
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.23.3 和 Istio 1.23.4 之间的区别。

本次发布实现了 12 月 18 日公布的安全更新
[`ISTIO-SECURITY-2024-007`](/zh/news/security/istio-security-2024-007)。

{{< relnote >}}

## 变更 {#changes}

- **新增** 添加了向 `istio-cni` Chart 提供任意环境变量的支持。

- **修复** 修复了将 `Duration` 与 `EnvoyFilter`
  合并可能导致所有侦听器相关属性意外被修改的问题，
  因为所有侦听器共享相同的指针类型 `listener_filters_timeout`。

- **修复** 修复了 Helm 渲染问题，以便在 Pilot 的 `ServiceAccount` 上正确应用注解。
  ([Issue #51289](https://github.com/istio/istio/issues/51289))

- **修复** 修复了当 Sidecar 注入器无法处理 Sidecar 配置时，
  注入配置错误被忽略（即记录但未返回）的问题。
  此更改现在会将错误传播给用户，而不是继续处理错误的配置。
  ([Issue #53357](https://github.com/istio/istio/issues/53357))

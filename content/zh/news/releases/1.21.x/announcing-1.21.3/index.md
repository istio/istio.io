---
title: 发布 Istio 1.21.3
linktitle: 1.21.3
subtitle: 补丁发布
description: Istio 1.21.3 补丁发布。
publishdate: 2024-06-04
release: 1.21.3
---

本次发布实现了 6 月 4 日公布的安全更新 [`ISTIO-SECURITY-2024-004`](/zh/news/security/istio-security-2024-004)
并修复了一些错误，提高了稳健性。

本发布说明描述了 Istio 1.21.2 和 Istio 1.21.3 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了使用域名地址构建 EDS 类型集群端点的问题。
  ([Issue #50688](https://github.com/istio/istio/issues/50688))

- **修复** 修复了当设置 `SecurityContext.RunAs` 字段时 `istio-proxy` 容器的自定义注入无法正常工作的问题。

- **修复** 修复了 Istio 1.21.0 中的回归问题，当配置了 `ENABLE_EXTERNAL_NAME_ALIAS=false` 时，
  该问题导致 `VirtualService` 到 `ExternalName` 服务的路由不起作用。

- **修复** 修复了 JWT Token 中的 Audience Claim 列表匹配问题。
  ([Issue #49913](https://github.com/istio/istio/issues/49913))

- **修复** 修复了 Istio 1.20 中的行为变化，该变化导致合并具有相同主机名和端口名的 `ServiceEntries` 时产生意外结果。
  ([Issue #50478](https://github.com/istio/istio/issues/50478))

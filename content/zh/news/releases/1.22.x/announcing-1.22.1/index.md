---
title: 发布 Istio 1.22.1
linktitle: 1.22.1
subtitle: 补丁发布
description: Istio 1.22.1 补丁发布。
publishdate: 2024-06-04
release: 1.22.1
---

本次发布实现了 6 月 4 日公布的安全更新 [`ISTIO-SECURITY-2024-004`](/zh/news/security/istio-security-2024-004)
并修复了一些错误，提高了稳健性。

本发布说明描述了 Istio 1.22.0 和 Istio 1.22.1 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **新增** 添加了一个新的、可选的实验性准入策略，该策略仅允许在使用远程 Istiod 集群时在 Istio API 中使用稳定的功能/字段。
  ([Issue #173](https://github.com/istio/enhancements/issues/173))

-**修复** 修复了将 Pod IP 添加到主机的 `ipset` 时明确失败而不是静默覆盖的问题。

- **修复** 修复了导致 MeshConfig 中的 `outboundstatname` 不适用于子集集群的问题。

- **修复** 修复了当设置 `SecurityContext.RunAs` 字段时 `istio-proxy` 容器的自定义注入无法正常工作的问题。

- **修复** 修复了启用 mTLS 后创建的自动直通网关返回 503 错误的问题。

- **修复** 修复了 `serviceRegistry` 顺序影响代理标签的问题，因此我们将 Kubernetes 注册表放在前面。
  ([Issue #50968](https://github.com/istio/istio/issues/50968))

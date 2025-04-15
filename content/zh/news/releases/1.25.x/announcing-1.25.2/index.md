---
title: 发布 Istio 1.25.2
linktitle: 1.25.2
subtitle: 补丁发布
description: Istio 1.25.2 补丁发布。
publishdate: 2025-04-14
release: 1.25.2
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.25.1 和 Istio 1.25.2 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **新增** 添加了环境变量前缀 `CA_HEADER_`（类似于 `XDS_HEADER_`），
  可将其添加到 CA 请求中以用于不同目的，例如路由到适当的外部 `istiod`。
  Istio Sidecar 代理、路由器和 waypoint 现在都支持此功能。
  ([Issue #55064](https://github.com/istio/istio/issues/55064))

- **修复** 修复了 `istio-cni` 可能阻止其自身升级的极端情况。
  添加了回退日志（以防代理程序关闭）到固定大小的节点本地日志文件。
  ([Issue #55215](https://github.com/istio/istio/issues/55215))

- **修复** 修复了 `AuthorizationPolicy` 的 `WaypointAccepted`
  状态条件未更新以反映 `GatewayClass` 目标引用的解析的问题。

- **修复** 修复了引用 `GatewayClass` 且不位于根命名空间中的
  `AuthorizationPolicies` 的 `WaypointAccepted`
  状态条件未使用正确的原因和消息进行更新的问题。

- **修复** 修复了 gRPC 流服务导致代理内存增加的问题。

- **修复** 修复了由于缓存驱逐错误导致对 `ExternalName` 服务的更改有时会被跳过的问题。

- **修复** 修复了 SDS `ROOTCA` 资源仅包含单个根证书的回归问题，
  即使控制平面配置了 1.25.1 中引入的主动根证书和被动根证书。
  ([Issue #55793](https://github.com/istio/istio/issues/55793))

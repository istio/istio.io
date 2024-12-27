---
title: 发布 Istio 1.22.4
linktitle: 1.22.4
subtitle: 补丁发布
description: Istio 1.22.4 补丁发布。
publishdate: 2024-08-19
release: 1.22.4
---

本发布说明描述了 Istio 1.22.3 和 Istio 1.22.4 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了自动注册期间缺少 `VirtualMachine` `WorkloadEntry` 位置标签的问题。
  ([Issue #51800](https://github.com/istio/istio/issues/51800))

- **修复** 修复了 `ServiceEntry` 中第一个地址以外的地址缺少监听器的问题。
  ([Issue #51747](https://github.com/istio/istio/issues/51747))

- **修复** 修复了与 `istio_agent_cert_expiry_seconds` 指标不一致的行为。

- **修复** 通过确保将 `.Values.profile` 设置为字符串，
  修复了旧版 Helm（`v3.6` 和 `v3.7`）的 istiod Chart 安装问题。
  ([Issue #52016](https://github.com/istio/istio/issues/52016))

- **修复** 修复了 ztunnel Helm Chart 中的遗漏，该遗漏会导致创建一些没有标签的 Kubernetes 资源。

- **修复** 修复了将 Pod 添加到数据平面时发生失败的问题，其中 Pod 仍然添加到 `ipset`。
  ([Issue #52218](https://github.com/istio/istio/issues/52218))

- **修复** 修复了导致资源被 `istioctl proxy-status` 错误地报告为 `STALE` 的问题。
  ([Issue #51612](https://github.com/istio/istio/issues/51612))

- **修复** 修复了当 `discoverySelectors`（在 `MeshConfig` 中配置）和具有
  `Ingress` 对象或 Kubernetes `Gateway` 对象的命名空间从选中变为未选中时可能触发死锁的问题。

- **修复** 修复了当多个 `WorkloadEntries` 中存在相同的 IP 地址时导致端点过时的问题。

- **移除** 删除了写入实验字段 `GatewayClass.status.supportedFeatures`，因为它在 API 中不稳定。

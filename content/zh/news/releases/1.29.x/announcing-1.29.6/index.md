---
title: 发布 Istio 1.29.6
linktitle: 1.29.6
subtitle: 补丁发布
description: Istio 1.29.6 补丁发布。
publishdate: 2026-07-16
release: 1.29.6
aliases:
    - /zh/news/announcing-1.29.6
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.29.5 和 Istio 1.29.6 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了 `EXIT_ON_ZERO_ACTIVE_CONNECTIONS` 从未在 Ambient 入口网关和 waypoint 上触发的问题，
  因为 Pilot-agent 的排出循环对 Envoy HBONE 内部侦听器
  （`connect_originate`、`connect_terminate`、`main_internal` 等）
  上的进程内连接进行了计数，从而防止活动连接计数达到零并强制代理等待 `terminationGracePeriodSeconds`。
  ([Issue #60728](https://github.com/istio/istio/issues/60728))

- **修复** 修复了非 Kubernetes 工作负载的自动注册 `WorkloadEntry`
  资源无法应用已发布的 HBONE 功能的问题。请注意，升级前自动注册的工作负载仍将通过明文访问，
  直到它们重新注册或在其现有 `WorkloadEntry` 中添加 `networking.istio.io/tunnel=http` 标签为止。

- **修复** 修复了 Ambient CNI 节点代理中的死锁，其中与 ztunnel（重新）连接并发的
  Pod 删除事件可能会永久阻止 ZDS 服务器。
  ([Issue ztunnel/1674](https://github.com/istio/ztunnel/issues/1674))

- **修复** 修复了 Istiod 中的内存泄漏，其中失败的 Pod IP 的 `needResync` 条目从未被清理。

- **修复** 修复了当目标服务具有 L7 `AuthorizationPolicy` 资源时，
  通过东西向网关的跨网络流量被虚假拒绝所有 RBAC 过滤器阻止。
  ([Issue #60806](https://github.com/istio/istio/issues/60806))

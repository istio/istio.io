---
title: 发布 Istio 1.26.3
linktitle: 1.26.3
subtitle: 补丁发布
description: Istio 1.26.3 补丁发布。
publishdate: 2025-07-29
release: 1.26.3
aliases:
    - /zh/news/announcing-1.26.3
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.26.2 和 Istio 1.26.3 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了 Ambient 索引用于遵循修订过滤配置。
  ([Issue #56477](https://github.com/istio/istio/issues/56477))

- **修复** 修复了使用 `discoverySelectors` 时系统命名空间中未正确跳过 `topology.istio.io/network` 标签的问题。
  ([Issue #56687](https://github.com/istio/istio/issues/56687))

- **修复** 修复了 CNI 插件在 Pod 尚未被标记为已注册到网格中时错误处理 Pod 删除的问题。
  在某些情况下，这可能会导致已删除的 Pod 被包含在 ZDS 快照中，
  并且永远不会被清理。如果发生这种情况，ztunnel 将无法准备就绪。
  ([Issue #56738](https://github.com/istio/istio/issues/56738))

- **修复** 修复了当引用的服务晚于遥测资源创建时访问日志未更新的问题。
  ([Issue #56825](https://github.com/istio/istio/issues/56825))

- **修复** 修复了启用 `ENABLE_CLUSTER_TRUST_BUNDLE_API` 时 `ClusterTrustBundle` 未被正确配置的问题。

- **修复** 修复了 Istio 访问日志不会发送到 OTLP 端点的问题。
  ([Issue 56825](https://github.com/istio/istio/issues/56825))

- **修复** 修复了如果另一个 Worker 正在积极处理某件事时，直到该 Worker 完成该事情为止，可能会出现 CPU 使用率过高的问题。

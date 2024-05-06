---
title: 发布 Istio 1.20.2
linktitle: 1.20.2
subtitle: 补丁发布
description: Istio 1.20.2 补丁发布。
publishdate: 2024-01-09
release: 1.20.2
---

本发布说明描述了 Istio 1.20.1 和 Istio 1.20.2 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **新增** 在 Helm Chart 中添加了网关 `HorizontalPodAutoscaler` 可配置的缩放行为。
  ([用法](https://kubernetes.io/zh-cn/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior))

- **修复** 修复了（例如在 `ServiceEntry` 中）通过通配符选中多个服务时，
  `VirtualService` 中因通配符造成的重叠主机会产生不正确路由配置的错误。
  ([Issue #45415](https://github.com/istio/istio/issues/45415))

- **修复** 修复了 Istio 在扩展时对 `StatefulSets` 和无头 `Service` 端点执行额外的 XDS 推送的问题。
  ([Issue #48207](https://github.com/istio/istio/issues/48207))

- **修复** 修复了 Istio 注入 Webhook 可能在试运行模式下被修改的问题。
  ([Issue #48241](https://github.com/istio/istio/issues/48241))

- **修复** 修复了如果 `DestinationRule` 的 `exportTo`
  包含工作负载的当前命名空间（不是 '.'），则其他命名空间会被 `exportTo` 忽略的问题。
  ([Issue #48349](https://github.com/istio/istio/issues/48349))

- **修复** 修复了启用双栈时未正确创建 QUIC 侦听器的问题。
  ([Issue #48336](https://github.com/istio/istio/issues/48336))

- **修复** 修复了 `istioctl proxy-config ecds` 未显示所有 `EcdsConfigDump` 的问题。

- **修复** 修复了新端点可能无法被发送到代理的问题。
  ([Issue #48373](https://github.com/istio/istio/issues/48373))

- **修复** 修复了使用 Stackdriver 安装并使用自定义配置会阻止 Stackdriver 被启用的问题。

- **修复** 修复了 TCP 和 gRPC 长连接可能导致代理内存泄漏的问题。

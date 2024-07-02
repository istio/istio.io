---
title: 发布 Istio 1.22.2
linktitle: 1.22.2
subtitle: 补丁发布
description: Istio 1.22.2 补丁发布。
publishdate: 2024-06-27
release: 1.22.2
---

本次发布实现了 6 月 27 日公布的安全更新 [`ISTIO-SECURITY-2024-005`](/zh/news/security/istio-security-2024-005)
并修复了一些错误，提高了稳健性。

本发布说明描述了 Istio 1.22.1 和 Istio 1.22.2 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **改进** 改进了 waypoint 代理不再以 root 身份运行的问题。

- **新增** 添加了 `gateways.securityContext` 到清单中，以提供自定义网关 `securityContext` 的选项。
  ([Issue #49549](https://github.com/istio/istio/issues/49549))

- **新增** 在 ztunnel 中添加了一个新选项，以完全禁用 IPv6，从而可以在禁用 IPv6 的内核上运行。

- **修复** 修复了 `istioctl analyze` 返回 IST0162 误报的问题。
  ([Issue #51257](https://github.com/istio/istio/issues/51257))

- **修复** 修复了 `ENABLE_ENHANCED_RESOURCE_SCOPING` 不属于 Istio 1.20/1.21 的 Helm 兼容性配置文件的一部分的问题。
  ([Issue #51399](https://github.com/istio/istio/issues/51399))

- **修复** 修复了尽管处于终止状态，但 Kubernetes Job Pod IP 可能无法完全从 Ambient 中取消注册的问题。

- **修复** 当设置 `credentialName` 和 `workloadSelector` 时，修复了 IST0128 和 IST0129 中的误报问题。
  ([Issue #51567](https://github.com/istio/istio/issues/51567))

- **修复** 修复了当获取其他 URI 时出现错误时，从 URI 获取的 JWKS 未及时更新的问题。
  ([Issue #51636](https://github.com/istio/istio/issues/51636))

- **修复** 修复了导致 `workloadSelector` 策略应用于 ztunnel 中错误命名空间的问题。
  ([Issue #51556](https://github.com/istio/istio/issues/51556))

- **修复** 修复了导致 `discoverySelectors` 意外过滤掉所有 `GatewayClasses` 的错误。

- **修复** 修复了证书链解析，通过修剪不必要的中间证书来避免不必要的解析错误。

- **修复** 修复了 Ambient 模式中的一个错误，该错误导致 Pod 生命周期开始时的请求被拒绝并显示 `unknown source`。

- **修复** 修复了 ztunnel 中一些预期的连接终止被报告为错误的问题。

- **修复** 修复了当使用仅存在于部分 Pod 上的 `targetPort` 连接服务时 ztunnel 中出现的问题。

- **修复** 修复了当多个 `ServiceEntry` 中存在重复的主机名时删除 `ServiceEntry` 时出现的问题。

- **修复** 修复了当连接到 `LoadBalancer` IP 时，
  ztunnel 会直接发送到 Pod，而不是经过 `LoadBalancer` 的问题。

- **修复** 修复了 ztunnel 会将流量发送到终止 Pod 的问题。

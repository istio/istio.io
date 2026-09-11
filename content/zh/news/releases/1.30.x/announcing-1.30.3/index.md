---
title: 发布 Istio 1.30.3
linktitle: 1.30.3
subtitle: 补丁发布
description: Istio 1.30.3 补丁发布。
publishdate: 2026-07-16
release: 1.30.3
aliases:
    - /zh/news/announcing-1.30.3
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.30.2 和 Istio 1.30.3 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **新增** 添加了通过 `PILOT_NODE_UNTAINT_CONTROLLERS_TAINT_NAME`
  环境变量对试点节点无污染控制器的自定义污染名称的支持。
  默认为 `cni.istio.io/not-ready`。
  ([Issue #57844](https://github.com/istio/istio/issues/57844))

- **改进** 通过将 XDS 推送从工作负载/服务 `Address` 更改范围限定为仅受影响的 waypoint，
  而不是推送到所有 waypoint 和代理，改进 Ambient 模式下的 istiod 可扩展性。
  可以通过 `AMBIENT_SCOPED_ADDRESS_PUSHES=false` 禁用。

- **修复** 修复了 pilot-agent 在第二次和后续 Kubernetes Secret 轮换中丢失文件安装证书的证书重新加载。
  ([Issue #59912](https://github.com/istio/istio/issues/59912))

- **修复** 修复了当默认将当前命名空间包含为 `.` 时，
  `meshConfig.defaultServiceExportTo` 和 `meshConfig.defaultVirtualServiceExportTo`
  中的其他命名空间不被接受的问题。
  ([Issue #60560](https://github.com/istio/istio/issues/60560))

- **修复** 修复了 istiod 在重新启动之前无法获取更新的远程集群 Secret（例如在凭证/令牌轮换期间）的错误。
  新的集群注册表可能会死锁等待同步，从而使受影响的远程集群的服务注册表陈旧。
  ([Issue #60612](https://github.com/istio/istio/issues/60612))

- **修复** 修复了 Istio 1.30 中引入的问题，其中对 `VirtualService` 资源
  （例如 Helm 注释、Argo CD 标签或 `kubectl.kubernetes.io/last-applied-configuration`）
  的仅元数据更改触发了对所有代理的不必要的 XDS 推送。这可能会导致控制平面 CPU 使用率显着增加，
  并且在具有由 GitOps 工具管理的许多 `VirtualService` 资源的集群中推送延迟。
  该修复恢复了 1.30 之前的行为，其中只有规范更改或 `istio.io` 标签/注解更改才会触发推送。
  ([Issue #60629](https://github.com/istio/istio/issues/60629))

- **修复** 修复了一个错误，即引用不同命名空间中的路径点的 `Service`
  没有将命名空间范围的 `Telemetry` 资源包含在其配置中。
  ([Issue #60665](https://github.com/istio/istio/issues/60665))

- **修复** 修复了 waypoint 入站路由的默认 HTTP 重试。
  `meshConfig.defaultHttpRetryPolicy` 设置现在适用于附加到 waypoint 的本地服务。
  ([Issue #60682](https://github.com/istio/istio/issues/60682))

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

- **修复** 修复了一个错误，即应用程序命名空间中的 `WasmPlugin` 通过
  `targetRefs` 定位 `Service` 会导致 waypoint 代理在启动时崩溃循环。
  LDS 路径正确地包含了 waypoint 的插件，但 ECDS 查找路径将其视为跨命名空间而拒绝，
  使 Envoy 等待永远不会到达的资源。
  ([Issue #60530](https://github.com/istio/istio/issues/60530))

- **修复** 修复了当目标服务具有 L7 `AuthorizationPolicy` 资源时，
  通过东西向网关的跨网络流量被虚假拒绝所有 RBAC 过滤器阻止。
  ([Issue #60806](https://github.com/istio/istio/issues/60806))

---
title: Istio 1.27 升级说明
description: 升级到 Istio 1.28.0 时要考虑的重要变更。
weight: 20
---

当您从 Istio 1.27.x 升级到 Istio 1.28.0 时，您需要考虑本页所述的变更。
这些说明详述了故意打破 Istio 1.27.x 向后兼容性的一些变更。
这些说明还提到了在引入新特性的同时保持向后兼容性的一些变更。
这里仅包含出乎 Istio 1.27.x 用户意料的新特性变更。

## 为 Sidecar 容器启用 `seccompProfile` {#enabling-seccompprofile-for-sidecar-containers}

要为 `istio-validation` 和 `istio-proxy`
容器启用 `RuntimeDefault` 安全计算模式配置文件
`seccompProfile`，请在 Istio 配置中进行以下设置：

{{< text yaml >}}
global:
  proxy:
    seccompProfile:
      type: RuntimeDefault
{{< /text >}}

此项更改通过使用容器运行时提供的默认 `seccompProfile` 来实现更好的安全实践。

## InferencePool

InferencePool API 现已发布至 v1.0.0 版本。
如果您正在使用之前的不稳定版本，请改用 v1 版本的 InferencePool API 类型。
请注意，我们已不再支持 alpha 版本和候选发布版本。

**如果您是从 v1.0.0-rc.1 版本迁移，**请注意，`inferencePool.spec.endpointPickerRef.portNumber`字段已替换为 `inferencePool.spec.endpointPickerRef.port.number`。
`inferencePool.spec.endpointPickerRef.port` 字段为非指针类型，
当 `inferencePool.spec.endpointPickerRef.kind` 未设置或为 `Service` 时，
该字段为必填项。端口号 9002 不再被用于推断。

## 被设置为 `NONE` 的 ServiceEntry 的 Ambient 数据平面行为变更 {#ambient-data-plane-behavior-changes-for-serviceentries-with-resolution-set-to-none}

从旧版本升级到支持“PASSTHROUGH”服务的版本时，
旧的 ztunnel 镜像会在 XDS 中报告 NACK，因为它们不支持这种新的服务类型。
这是预期行为，通常不会造成太大问题，但看到 NACK 可能意味着数据平面行为发生了变化。
升级过程中，NACK 可能导致以下情况：

1. 由于数据平面配置无法处理新的服务类型，因此未进行更新。这实际上相当于一次空操作更新。
1. 该服务是新创建的，数据平面尚未接受其配置。
  这将导致数据平面表现得如同 ServiceEntry 不存在一样。因此，
  ztunnel 无法识别该服务，也无法确定是否需要 waypoint，从而导致直通行为。

无论哪种情况，一旦 ztunnel 更新到支持新服务类型的版本，NACK 行为就会得到解决。

## `BackendTLSPolicy` Alpha 移除 {#backendtlspolicy-alpha-removal}

已移除对 `BackendTLSPolicy` v1alpha3 版本的支持。
目前仅支持 `BackendTLSPolicy` v1 版本。

请注意，在此版本之前，除非显式启用 `PILOT_ENABLE_ALPHA_GATEWAY_API=true` 选项，
否则 Istio 会忽略 `BackendTLSPolicy`。由于该策略现在已升级到 `v1` 版本，因此不再需要此设置。

## 迁移到新的指标淘汰机制 {#migrate-to-the-new-metric-eviction-mechanism}

Pilot 环境标志 `METRIC_ROTATION_INTERVAL` 和 `METRIC_GRACEFUL_DELETION_INTERVAL` 已被移除。
请改用新的统计驱逐 API 和 Pod 注解 `sidecar.istio.io/statsEvictionInterval`。

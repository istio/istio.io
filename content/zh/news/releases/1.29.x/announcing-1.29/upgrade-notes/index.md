---
title: 升级说明
description: 升级到 Istio 1.29.0 时要考虑的重要变更。
weight: 20
---

当您从 Istio 1.28.x 升级到 Istio 1.29.0 时，需要注意此页面上的变更。
这些说明详细说明了有意破坏与 Istio 1.28.x 向后兼容性的变更。
此外，这些说明还提及了在保持向后兼容性的同时引入新行为的变更。
只有当新行为对 Istio 1.28.x 用户而言是意料之外的，才会包含这些变更。

## 默认启用 Envoy 指标（`prometheus_stats`）的 HTTP 压缩 {#http-compression-of-envoy-metrics-prometheus_stats-enabled-by-default}

注解 `sidecar.istio.io/statsCompression` 已被弃用并移除。

现在 `proxyConfig` 中新增了一个 `statsCompression` 选项，
用于全局控制 Envoy 指标端点 (`prometheus_stats`) 的压缩支持。
默认值为 `true`，根据客户端发送的 `Accept-Header` 提供 `brotli`、`gzip` 和 `zstd` 三种压缩方式。

大多数指标抓取工具都允许单独配置压缩设置。如果您仍然需要为每个 Pod 单独设置压缩，
可以通过 `proxy.istio.io/config` 注解设置 `statsCompression: false`。

## 默认启用 Ambient DNS 捕获 {#ambient-dns-capture-enabled-by-default}

此版本默认为 Ambient 工作负载启用 DNS 代理。请注意，只有新创建的 Pod 才会启用 DNS；
现有 Pod 的 DNS 流量不会被捕获。要为现有 Pod 启用此功能，必须手动重启现有 Pod，
或者也可以在升级 `istio-cni` 时通过 `--set cni.ambient.reconcileIptablesOnStartup=true`
启用 iptables 协调功能，这样升级时会自动协调现有 Pod。

## 在 Ambient 模式下使用试运行授权策略进行升级 {#upgrading-in-ambient-mode-with-dry-run-authorizationpolicy}

如果您使用试运行 `AuthorizationPolicy` 并希望启用此新功能，
则升级到 1.29 版本时需要注意一些重要事项。在 Istio 1.29 版本之前，
ztunnel 不具备处理试运行 `AuthorizationPolicy` 的功能。
因此，istiod 不会向 ztunnel 发送任何试运行策略。Istio 1.29
版本在 ztunnel 中引入了对试运行 `AuthorizationPolicy` 的实验性支持。
设置 `AMBIENT_ENABLE_DRY_RUN_AUTHORIZATION_POLICY=true` 将使 istiod 开始使用
xDS 中的一个新字段向 ztunnel 发送试运行策略。低于 1.29 版本的 ztunnel 不支持此字段。
因此，旧版本的 ztunnel 将完全强制执行这些策略，这可能会导致意外结果。
为确保顺利升级，必须确保所有连接到启用此功能的 istiod 的 ztunnel 代理都足够新，能够正确处理这些策略。

## 默认启用调试端点授权 {#debug-endpoint-authorization-enabled-by-default}

从非系统命名空间访问调试端点的工具（例如 Kiali 或自定义监控工具）可能会受到影响。
现在，非系统命名空间仅限于访问同命名空间代理的 `config_dump`、`ndsz` 和 `edsz` 端点。
要恢复之前的行为，请设置 `ENABLE_DEBUG_ENDPOINT_AUTH=false`。

## 熔断机制指标追踪行为变化 {#circuit-breaker-metrics-tracking-behavior-change}

熔断器剩余指标跟踪的默认行为已更改。此前，这些指标默认处于跟踪状态。
现在，为了更好地利用代理内存，默认情况下已禁用跟踪。

要保持之前跟踪剩余指标的行为，您可以：

1. 在 istiod 部署中设置环境变量 `DISABLE_TRACK_REMAINING_CB_METRICS=false`
1. 使用兼容版本功能获取旧版行为

此更改会影响 Envoy 断路器配置中的 `TrackRemaining` 字段。

## Base Helm Chart 的移除项 {#base-helm-chart-removals}

在之前的版本中，`base` Helm Chart 中存在的许多配置被**复制**到 `istiod` Chart 中。

在此版本中，重复的配置已从 `base` Chart 中完全移除。

下表显示了旧配置到新配置的映射关系：

| 旧的                                     | 新的                                     |
| --------------------------------------- | --------------------------------------- |
| `ClusterRole istiod`                    | `ClusterRole istiod-clusterrole`        |
| `ClusterRole istiod-reader`             | `ClusterRole istio-reader-clusterrole`  |
| `ClusterRoleBinding istiod`             | `ClusterRoleBinding istiod-clusterrole` |
| `Role istiod`                           | `Role istiod`                           |
| `RoleBinding istiod`                    | `RoleBinding istiod`                    |
| `ServiceAccount istiod-service-account` | `ServiceAccount istiod`                 |

注意：大多数资源都会自动添加一个后缀。在旧版图表中，该后缀为 `-{{ .Values.global.istioNamespace }}`。
在新版图表中，命名空间范围的资源后缀为 `{{- if not (eq .Values.revision "") }}-{{ .Values.revision }}{{- end }}`，
集群范围的资源后缀为 `{{- if not (eq .Values.revision "")}}-{{ .Values.revision }}{{- end }}-{{ .Release.Namespace }}`。

## 默认启用 Ambient iptables 调谐 {#ambient-iptables-reconciliation-enabled-by-default}

在 1.29.0 版本中，Ambient 工作负载默认启用 iptables 规则协调。
当一个新的 istio-cni `DaemonSet` Pod 启动时，它会自动检查之前已加入 Ambient 网格的 Pod，
并在发现任何差异时将其 Pod 内的 iptables/nftables 规则更新到当前状态。
可以使用 `--set cni.ambient.reconcileIptablesOnStartup=false` 显式禁用此功能。

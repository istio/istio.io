---
title: Istio 1.25 升级说明
description: 升级到 Istio 1.25.0 时要考虑的重要变更。
weight: 20
publishdate: 2025-03-03
---

当您从 Istio 1.24.x 升级到 Istio 1.25.x 时，您需要考虑本页所述的变更。
这些说明详述了故意打破 Istio 1.24.x 向后兼容性的一些变更。
这些说明还提到了在引入新特性的同时保持向后兼容性的一些变更。
这里仅包含出乎 Istio 1.24.x 用户意料的新特性变更。

## Ambient 模式 Pod 升级调协 {#ambient-mode-pod-upgrade-reconciliation} 

当新的 `istio-cni` `DaemonSet` Pod 启动时，它将检查先前在 Ambient 网格中注册的 Pod，
并将它们内的 iptables 规则升级到当前状态，如存在差异或区别。
从 1.25.0 开始，此功能默认关闭，但未来最终将默认启用。
可以通过 `helm install cni --set ambient.reconcileIptablesOnStartup=true`（Helm）或
`istioctl install --set values.cni.ambient.reconcileIptablesOnStartup=true`（istioctl）启用此功能。

## DNS 流量（TCP 和 UDP）现在遵守流量排除注解 {#dns-traffic--tcp-and-udp--now-respects-traffic-exclusion-annotations}

DNS 流量（UDP 和 TCP）现在遵守 Pod 级流量注解，
例如 `traffic.sidecar.istio.io/excludeOutboundIPRanges` 和 `traffic.sidecar.istio.io/excludeOutboundPorts`。
以前，由于规则结构的原因，即使指定了 DNS 端口，UDP/DNS 流量也会唯一地忽略这些流量注解。
此行为更改实际上发生在 1.23 版本系列中，但未包含在 1.23 的发行说明中。

## 默认开启 Ambient 模式 DNS 捕获 {#ambient-mode-dns-capture-on-by-default}

在此版本中，默认情况下，Ambient 模式工作负载启用了 DNS 代理。
请注意，只有新 Pod 才会启用 DNS：现有 Pod 的 DNS 流量不会被捕获。
要为现有 Pod 启用此功能，必须手动重启它们，或者在升级 `istio-cni`
时通过 `--set cni.ambient.reconcileIptablesOnStartup=true` 启用 iptables 协调功能。
这将在升级时自动协调现有 Pod。

各个 Pod 可以通过应用 `ambient.istio.io/dns-capture=false` 注解来退出全局 Ambient 模式 DNS 捕获。

## Grafana 仪表板变更 {#grafana-dashboard-changes} 

Istio 1.25 附带的仪表板需要 Grafana 7.2 或更高版本。

## OpenCensus 支持已被移除 {#opencensus-support-has-been-removed}

由于 Envoy 已[移除 OpenCensus 链路追踪扩展](https://www.envoyproxy.io/docs/envoy/latest/version_history/v1.33/v1.33.0.html#incompatible-behavior-changes)，
我们已从 Istio 中移除 OpenCensus 支持。如果您正在使用 OpenCensus，
则应迁移到 OpenTelemetry。[详细了解 OpenCensus 的弃用情况](https://opentelemetry.io/blog/2023/sunsetting-opencensus/)。

## ztunnel Helm Chart 变更 {#ztunnel-helm-chart-changes}

在以前的版本中，ztunnel Helm Chart 中的资源始终命名为 `ztunnel`。
在此版本中，它们现在被命名为 `.Resource.Name`。

如果您安装的 Chart 的发布名称不是 `ztunnel`，则资源名称将发生变化，
从而导致停机。在这种情况下，建议设置 `--set resourceName=ztunnel` 以覆盖回以前的默认值。

---
title: Istio 1.27 升级说明
description: 升级到 Istio 1.27.0 时要考虑的重要变更。
weight: 20
---

当您从 Istio 1.26.x 升级到 Istio 1.27.x 时，您需要考虑本页所述的变更。
这些说明详述了故意打破 Istio 1.26.x 向后兼容性的一些变更。
这些说明还提到了在引入新特性的同时保持向后兼容性的一些变更。
这里仅包含出乎 Istio 1.26.x 用户意料的新特性变更。

## 网关支持多种证书类型 {#multiple-certificate-types-support-in-gateway}

Istio 现在支持在 Istio 和 Kubernetes Gateway
资源中同时配置多种证书类型（例如 RSA 和 ECDSA）。这允许客户端根据其功能选择最合适的证书类型。

## 升级后重新生成 Grafana 仪表板 {#regenerate-grafana-dashboards-after-upgrade}

如果您使用 Istio 捆绑的 Grafana 仪表板，则需要在升级后重新生成它们以获得固定的仪表板链接。
现在已明确定义仪表板 UID，以便在仪表板之间建立稳定的链接。

## 弃用可观测提供商 {#deprecation-of-telemetry-providers}

可观测提供商 Lightstep 和 OpenCensus 现已被移除。请改用 OpenTelemetry 提供商。

## 默认启用原生 Sidecar {#native-sidecar-enabled-by-default}

现在，符合条件的 Pod 默认启用原生 Sidecar。这将把 `istio-proxy`
从容器更改为 Init 容器。这可能会导致与集群中其他需要将 `istio-proxy`
修改为常规容器的 Mutating Webhook 或控制器出现兼容性问题。
请测试您的工作负载和控制器，以确保它们与此更改兼容。

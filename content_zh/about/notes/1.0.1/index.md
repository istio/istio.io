---
title: Istio 1.0.1
weight: 91
icon: notes
---

本次发布解决了一些社区在使用 Istio 1.0 过程中发现的关键问题。本发布声明描述了 Istio 1.0 和 Istio 1.0.1 之间的区别。

## 网络

- 改善了 Pilot 的可伸缩性和 Envoy 的启动时间。

- 修复了增加一个端口时 VirtualService Host 不匹配的问题。

- 添加了同一个主机内对 [合并多个 `VirtualService` 或 `DestinationRule` 定义](/help/ops/traffic-management/deploy-guidelines/#multiple-virtual-services-and-destination-rules-for-the-same-host) 的有限支持。

- 允许在使用 HTTP 时，连续的出现 Gateway failures [outlier](https://www.envoyproxy.io/docs/envoy/latest/api-v1/cluster_manager/cluster_outlier_detection.html) 。

## 环境

- 允许使用独立的 Pilot, 便于用户仅适用 Istio 的流量管理功能。

- 介绍了 `values-istio-gateway.yaml` 这一很方便的配置，使用户可以运行独立的 Gateway。

- 修复了多个 Helm 安装问题，包括找不到 `istio-sidecar-injector` configmap 的问题。

- 修复了由于 Galley 还没有准备好导致的 Istio 安装错误。

- 修复了关于网格扩展的一系列问题。

## 策略与遥测

- 为 Mixer 的 Prometheus 适配器新增了一个实验性的监控指标过期配置。

- 将 Grafana 升级至 5.2.2 版本。

### 适配器

- 能够指定 Stackdriver 适配器的 Sink 选项。

## Galley

- 改善了健康检查的配置验证。

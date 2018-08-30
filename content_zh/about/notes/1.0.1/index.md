---
title: Istio 1.0.1
weight: 91
icon: /img/notes.svg
---

此版本解决了社区在使用 Istio 1.0 时发现的一些关键问题。本发行说明描述了 Istio 1.0 和 Istio 1.0.1 之间的不同之处。

{{< relnote_links >}}

## 网络

- 改进了 Pilot 可扩展性和 Envoy 启动时间。

- 修复了添加端口时虚拟服务主机不匹配的问题。

- 为[合并多个虚拟服务或目标规则定义](/help/ops/traffic-management/deploy-guidelines/#multiple-virtual-services-and-destination-rules-for-the-same-host)增加了同一主机记得限制。

- 使用 HTTP 时，允许 [outlier](https://www.envoyproxy.io/docs/envoy/latest/api-v1/cluster_manager/cluster_outlier_detection.html) 连续网关故障。

## 环境

- 对于那些只想利用 Istio 流量管理功能的用户，可以使用 Pilot standalone。

- 引入了方便的 `values-istio-gateway.yaml` 配置，使用户能够运行独立的网关。

- 修复了各种 Helm 安装问题，包括找不到 `istio-sidecar-injector` 配置映射的问题。

- 修复了 Galley 未准备好的 Istio 安装错误。

- 修复了网格扩展的各种问题。

## 策略和遥测

- 为 Mixer Prometheus 适配器添加了实验指标到期配置。

- 将 Grafana 更新至 5.2.2。

### 适配器

- 能够为 Stack driver 适配器指定接收器选项。

## Galley

- 改进了健康检查的配置验证。

---
title: Istio 1.0.1 发布公告
linktitle: 1.0.1
subtitle: 补丁发布
description: Istio 1.0.1 补丁发布。
publishdate: 2018-08-29
release: 1.0.1
aliases:
    - /zh/about/notes/1.0.1
    - /zh/blog/2018/announcing-1.0.1
    - /zh/news/2019/announcing-1.0.1
    - /zh/news/announcing-1.0.1
---

我们很高兴的宣布 Istio 1.0.1 现已正式发布。下面是更新详情。

{{< relnote >}}

## 网络{#networking}

- 改进了 Pilot 的可扩展性和 Envoy 的启动时间。

- 修复了添加端口时，虚拟服务 host 不匹配的 bug。

- 增加了对[合并同一主机的多个虚拟服务或目标规则定义](/zh/docs/ops/best-practices/traffic-management/#split-virtual-services) 的有限支持。

- 使用HTTP时，允许连续的[异常](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/cluster/outlier_detection.proto)网关故障。

## 环境{#environment}

- 对于那些只想使用 Istio 流量管理功能的用户，Pilot 现在可以独立使用。

- 引入了方便的配置 `values-istio-gateway.yaml`，该配置使用户能够运行独立网关。

- 修复了一堆 Helm 的安装问题，包括 `istio-sidecar-injector` 找不到配置映射的 bug。

- 修复了 Galley 尚未准备就绪的 Istio 安装 bug。

- 修复了有关网格扩展的各种 bug。

## 策略和遥测{#policy-and-telemetry}

- 向 Mixer Prometheus 适配器添加了实验性的指标过期配置。

- Grafana 升级至 5.2.2。

### 适配器{#adapters}

- 现在可以为 Stackdriver 适配器指定接收器选项。

## Galley

- 改进健康检查的配置验证。

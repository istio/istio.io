---
title: 本地负载均衡
description: 有关如何启用和理解本地负载均衡的信息。
weight: 40
keywords: [locality,load balancing,priority,prioritized]
---

地点使用以下三元组定义了网格中的地理位置：

- 地区（Region）
- 区域（Zone）
- 分区（Sub-zone）

地理位置通常代表数据中心。Istio 使用此信息对负载均衡池进行优先级排序，以控制发送请求的地理位置。

## 启用本地负载均衡

此功能是实验性的，Istio 1.1 版本默认启用。
要启用本地负载均衡，需要在所有 Pilot 实例中设置 `PILOT_ENABLE_LOCALITY_LOAD_BALANCING` 环境变量。

目前，服务发现平台会自动填充地点信息。

在 Kubernetes 中，一个 Pod 的地点是由其运行节点的[知名地区（Region）和区域（Zone）标签](https://kubernetes.io/docs/reference/kubernetes-api/labels-annotations-taints/#failure-domain-beta-kubernetes-io-region)确定的。
如果您使用托管的 Kubernetes 服务，您的云提供商应该为您配置地点信息。
如果您正在运行自己的 Kubernetes 集群，则需要将这些标签添加到您的节点。
Kubernetes 中不存在分区（Sub-zone）的概念。因此，不需要配置此字段。  

## 本地优先的负载均衡  

_Locality-prioritized load balancing_ 是 _locality load balancing_ 的默认行为。

在这种模式下，Istio 告诉 Envoy 将流量优先分配给与发送请求的 Envoy 位置最匹配（最近）的工作负载实例。
当所有实例都正常运行时，请求将保持在同一地点。
当实例变得不健康时，流量会被调度到位于下一个优先级位置的实例上。
这种行为一直持续到所有地点都接收到流量为止。
您可以在 [Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/load_balancing/priority#priority-levels)中找到确切的百分比。  

具有 `us-west/zone2` 地点标识的 Envoy 典型优先顺序如下：  

- 优先级 0: `us-west/zone2`
- 优先级 1: `us-west/zone1`, `us-west/zone3`
- 优先级 2: `us-east/zone1`, `us-east/zone2`, `eu-west/zone1`

优先级的层次结构按以下顺序匹配：

1. 地区（Region）
1. 区域（Zone）
1. 分区（Sub-zone）

在同一区域（Zone）但不同地区（Region）的代理不被认为是彼此互为本地的。  

### 覆写地点故障转移

有时，您需要限制流量故障转移功能，以避免在同一地区没有足够的健康端点时将流量发送到全球各地的端点。
当跨地区传输失败不会改善服务健康状况或许多其他原因（包括遇到监管控制）时，这种特性非常有用。

要限制地区的流量，请使用网格的 `LocalityLoadBalancerSetting.Failover` 参数进行配置，
具体配置内容参见[本地负载均衡参考指南](/zh/docs/reference/config/istio.networking.v1alpha3/#loadbalancersettings)。

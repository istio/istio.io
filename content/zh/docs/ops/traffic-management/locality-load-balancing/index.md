---
title: 地域负载均衡
description: 有关如何启用和理解地域负载平衡。
weight: 98
keywords: [locality,load balancing,priority,prioritized]
aliases:
    - /zh/help/ops/traffic-management/locality-load-balancing
    - /zh/help/ops/locality-load-balancing
    - /zh/help/tasks/traffic-management/locality-load-balancing
---

地域由如下三元组在网格中定义了地理位置：

- Region
- Zone
- Sub-zone

地理位置通常代表数据中心。Istio 使用该信息来优化负载均衡池，用以控制请求发送到的地理位置。

## 配置地域负载均衡{#configuring-locality-load-balancing}

该特性默认开启。要禁用地域负载均衡，在安装 Istio 时通过配置 `--set global.localityLbSetting.enabled=false` 即可。

## 需求{#requirements}

目前，服务发现平台会自动填充地域。

在 Kubernetes 中，Pod 的地域是通过在已部署的节点上的 [Region 和 Zone 的标签](https://kubernetes.io/docs/reference/kubernetes-api/labels-annotations-taints/#failure-domain-beta-kubernetes-io-region)决定的。
如果您正在使用托管的 Kubernetes 服务，那么云供应商会进行配置。
如果您正在运行自己的 Kubernetes 集群，那么需要将这些标签添加到您的节点中。
Kubernetes 中不存在 sub-zone 的概念。因此，该字段不需要配置。

为了让 Istio 确定地域，服务必须与调用方进行关联。

为了确定实例何时异常，对于每个服务的代理，在 destination rule 中需要配置一份[异常检测](/zh/docs/reference/config/networking/destination-rule/#OutlierDetection)。

## 地域优先负载均衡{#locality-prioritized-load-balancing}

_地域优先负载均衡_ 是 _地域负载均衡_ 的默认行为。
在该模式下，Istio 告知 Envoy 对最近匹配 Envoy 发送请求地域的负载实例进行流量优化。
当所有实例都正常时，请求将保持在同一地点。当实例变得异常时，流量会分发到下一优先地域的实例。
该行为会持续到所有地域都接收到流量。
您可以在 [Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/priority)中找到精确的百分比。

  {{< warning >}}
  如果 destination rules 中未定义异常检测配置，那么代理将无法确定实例是否正常，并且即使您启用了**地域优先**负载均衡，代理也可以全局路由流量。
  {{< /warning >}}

`us-west/zone2` 地域的 Envoy 典型优先级如下：

- 优先级 0: `us-west/zone2`
- 优先级 1: `us-west/zone1`, `us-west/zone3`
- 优先级 2: `us-east/zone1`, `us-east/zone2`, `eu-west/zone1`

优先级的层次结构按如下顺序匹配：

1. Region
1. Zone
1. Sub-zone

同一 zone 但不同 region 的代理不被认为同一地域的代理。

### 废除地域故障转移{#overriding-the-locality-fail-over}

有时，当同一 region 中没有足够正常的 endpoints 时，您需要限制流量故障转移来避免跨全局的流量转发。
当跨 region 的发送故障转移流量而不能改善服务运行状况或其他诸如监管政策等原因时，该行为是很有用的。
为了将流量限制到某一个 region，请在安装时配置 `values.localityLbSetting` 选项。
参考[地域负载均衡参考指南](/docs/reference/config/networking/destination-rule#LocalityLoadBalancerSetting)来获取更多选项。

配置示例：

{{< text yaml >}}
global:
  localityLbSetting:
    enabled: true
    failover:
    - from: us-east
      to: eu-west
    - from: us-west
      to: us-east
{{< /text >}}

## 地域加权负载均衡{#locality-weighted-load-balancing}

地域加权负载均衡将用户定义的一定百分比的流量分发到某些地域。

例如：如果我们想保留发送 80% 的流量到我们所处的 region，另外 20% 的流量发送到外部 region：

{{< text yaml >}}
global:
  localityLbSetting:
    enabled: true
    distribute:
    - from: "us-central1/*"
      to:
        "us-central1/*": 80
        "us-central2/*": 20
{{< /text >}}

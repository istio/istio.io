---
title: 流量分发
description: 在 Ambient 模式下，控制流量如何分发至端点。
weight: 35
owner: istio/wg-networking-maintainers
test: no
---

`networking.istio.io/traffic-distribution` 注解用于控制
{{< gloss >}}ztunnel{{< /gloss >}} 如何在可用端点之间分发流量。
这有助于将流量保持在本地，从而降低延迟和跨区域成本。

## 支持的值 {#supported-values}

| 值 | 行为 |
| --- | --- |
| `PreferSameZone` | 按邻近度对端点进行优先级排序：依次为网络、区域、可用区，最后是子可用区。流量将优先导向距离最近且状态正常的端点。 |
| `PreferClose` | `PreferSameZone` 的已弃用别名。请参阅 [Kubernetes 增强提案 3015](https://github.com/kubernetes/enhancements/tree/master/keps/sig-network/3015-prefer-same-node)。 |
| `PreferSameNode` | 优先选择与客户端位于同一节点的端点。 |
| （未设置） | 无地域偏好。流量将分发至所有健康端点。 |

## 应用注解 {#applying-the-annotation}

该注解可应用于：

- **`Service`**：影响流向该特定服务的流量
- **`Namespace`**：为该命名空间内的所有服务设置默认配置
- **`ServiceEntry`**：影响流向外部服务的流量

### 优先级 {#precedence}

当配置了多个层级时，最具体的层级优先。

1. `spec.trafficDistribution` 字段（仅限 `Service`）
1. `Service`/`ServiceEntry` 上的注解
1. `Namespace` 上的注解
1. 默认行为（无地域偏好）

## 示例 {#examples}

### 按服务配置 {#per-service-configuration}

应用于单个服务：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    networking.istio.io/traffic-distribution: PreferSameZone
spec:
  selector:
    app: my-app
  ports:
  - port: 80
{{< /text >}}

### 命名空间级配置 {#namespace-wide-configuration}

应用于命名空间内的所有服务：

{{< text yaml >}}
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
  annotations:
    networking.istio.io/traffic-distribution: PreferSameZone
{{< /text >}}

命名空间内的服务将继承此设置，除非它们拥有自己的注解。

### 覆盖命名空间默认值 {#override-namespace-default}

服务可以通过其自身的注解来覆盖命名空间设置：

{{< text yaml >}}
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
  annotations:
    networking.istio.io/traffic-distribution: PreferSameZone
---
apiVersion: v1
kind: Service
metadata:
  name: different-service
  namespace: my-namespace
  annotations:
    networking.istio.io/traffic-distribution: PreferSameNode
spec:
  selector:
    app: different-app
  ports:
  - port: 80
{{< /text >}}

未带注解的服务将继承命名空间设置。

## 行为 {#behavior}

### `PreferSameZone`

启用 `PreferSameZone` 后，ztunnel 会按地域对端点进行归类，并将流量路由至距离最近的健康端点：

1. 相同的网络、区域、可用区和子可用区
1. 相同的网络、区域和可用区
1. 相同的网络和区域
1. 相同的网络
1. 任意可用端点

如果较近区域内的所有端点均变为不健康状态，流量将自动故障转移至下一层级。

例如，一个在 `us-west`、`us-west` 和 `us-east` 区域拥有端点的服务：

- 位于 `us-west` 的客户端将所有流量发送至两个 `us-west` 端点。
- 若其中一个 `us-west` 端点发生故障，流量将流向剩余的那个 `us-west` 端点。
- 若两个 `us-west` 端点均发生故障，流量将故障转移至 `us-east`。

### `PreferSameNode`

启用 `PreferSameNode` 后，ztunnel 会优先选择运行在与客户端同一 Kubernetes 节点上的端点。
这有助于最大程度地减少节点本地通信的网络跳数和延迟。

## 与 Kubernetes `trafficDistribution` 的关系 {#relationship-to-kubernetes-trafficdistribution}

Kubernetes 1.31 为 `Service` 引入了 [`spec.trafficDistribution`](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#traffic-distribution)
字段。此 Istio 注解提供了相同的功能，并额外带来了以下优势：

| | `spec.trafficDistribution` | 注解 |
| --- | --- | --- |
| Kubernetes 版本 | 1.31+ | 任意 |
| `Service` | 是 | 是 |
| `ServiceEntry` | 否 | 是 |
| `Namespace` | 否 | 是 |

当 `Service` 上同时设置了 spec 字段和注解时，spec 字段具有优先权。

waypoint 自动配置此注解。

## 参见 {#see-also}

- [区域负载均衡](/zh/docs/tasks/traffic-management/locality-load-balancing/)，用于基于 Sidecar 的区域路由
- [注解参考](/zh/docs/reference/config/annotations/#NetworkingTrafficDistribution)

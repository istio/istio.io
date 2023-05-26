---
title: 地域负载均衡
description: 本系列任务演示如何在 Istio 中配置地域负载均衡。
weight: 65
keywords: [locality,load balancing,priority,prioritized,kubernetes,multicluster]
simple_list: true
content_above: true
aliases:
  - /help/ops/traffic-management/locality-load-balancing
  - /help/ops/locality-load-balancing
  - /help/tasks/traffic-management/locality-load-balancing
  - /zh/docs/ops/traffic-management/locality-load-balancing
  - /zh/docs/ops/configuration/traffic-management/locality-load-balancing
owner: istio/wg-networking-maintainers
test: n/a
---
一个 *地域* 定义了 {{< gloss >}}workload instance{{</ gloss >}} 在你的网格中的地理位置。这三个元素定义了一个地域：

- **地区**：代表较大的地理区域， 例如 *us-east*. 一个地区通常包含许多可用 *zones*。在 Kubernetes 中，
标签 [`topology.kubernetes.io/region`](https://kubernetes.io/zh-cn/docs/reference/labels-annotations-taints/#topologykubernetesioregion) 确定节点的区域。

- **区域**：区域内的一组计算资源。通过在区域内的多个区域中运行服务，可以在区域内的区域之间进行故障转移，
同时保持最终用户的数据地域性。在 Kubernetes 中，
标签 [`topology.kubernetes.io/zone`](https://kubernetes.io/zh-cn/docs/reference/labels-annotations-taints/#topologykubernetesiozone) 确定节点的区域。

- **分区**：允许管理员进一步细分区域，以实现更细粒度的控制，例如“相同机架”。
Kubernetes 中不存在分区的概念。结果 Istio 引入了自定义节点标签 [`topology.istio.io/subzone`](/zh/docs/reference/config/labels/#:~:text=topology.istio.io/subzone) 来定义分区。

{{< tip >}}
如果您使用托管的 Kubernetes 服务，则云提供商应为您配置区域和区域标签。
如果您正在运行自己的 Kubernetes 集群，则需要将这些标签添加到您的节点上。
{{< /tip >}}

地域是分层的，按匹配顺序排列：

1. 地区

1. 区域

1. 分区

这意味着，在 `foo` 地区的 `bar` 区域中运行 Pod 是 **不** 被认为是在 `baz` 地区的 `bar` 区域中运行的 Pod。

Istio 使用地域信息来控制负载平衡行为。按照本系列的任务一，为您的网格配置地域负载均衡。

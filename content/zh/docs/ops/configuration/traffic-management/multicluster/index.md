---
title: 多集群流量管理
description: 如何配置流量在网格集群之间如何分发的。
weight: 70
keywords: [traffic-management,multicluster]
owner: istio/wg-networking-maintainers
test: no
---

在多集群网格中，可能需要特定于集群拓扑的流量规则。本文件描述了在多集群网格中管理流量的几种方法，
在阅读本指南之前：

1. 阅读[部署模型](/zh/docs/ops/deployment/deployment-models/#multiple-clusters)。
1. 确保您部署的服务遵循以下概念{{< gloss "namespace sameness" >}}命名空间的相同{{< /gloss >}}。

## 保持集群内的流量 {#keeping-traffic-in-cluster}

在某些情况下，默认的跨集群负载平衡操作是不可取的。为了保持流量的 "cluster-local" (即：
从 `cluster-a` 发送的流量将只会到达 `cluster-a` 中的目的地)，
使用 [`MeshConfig.serviceSettings`](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ServiceSettings-Settings)
将主机名或通配符标记为 `clusterLocal`。

例如，您可以为单个服务、特定命名空间中的所有服务或网格中的所有服务全局实施 "cluster-local" 流量管理，如下所示：

{{< tabset category-name="meshconfig" >}}

{{< tab name="per-service" category-value="service" >}}

{{< text yaml >}}
serviceSettings:
- settings:
    clusterLocal: true
  hosts:
  - "mysvc.myns.svc.cluster.local"
{{< /text >}}

{{< /tab >}}

{{< tab name="per-namespace" category-value="namespace" >}}

{{< text yaml >}}
serviceSettings:
- settings:
    clusterLocal: true
  hosts:
  - "*.myns.svc.cluster.local"
{{< /text >}}

{{< /tab >}}

{{< tab name="global" category-value="global" >}}

{{< text yaml >}}
serviceSettings:
- settings:
    clusterLocal: true
  hosts:
  - "*"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 分区服务 {#partitioning-services}

[`DestinationRule.subsets`](/zh/docs/reference/config/networking/destination-rule/#Subset)
允许通过选择标签对服务进行分区。这些标签可以是来自Kubernetes metadata 的标签，
也可以是来自 [built-in labels](/zh/docs/reference/config/labels/)。
这些内置标签之一的 `topology.istio.io/cluster` 在
`DestinationRule` 的子集选择器中允许创建每个集群的子集。

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: mysvc-per-cluster-dr
spec:
  host: mysvc.myns.svc.cluster.local
  subsets:
  - name: cluster-1
    labels:
      topology.istio.io/cluster: cluster-1
  - name: cluster-2
    labels:
      topology.istio.io/cluster: cluster-2
{{< /text >}}

使用这些子集，您可以创建各种路由规则基于这些集群，如 [mirroring](/zh/docs/tasks/traffic-management/mirroring/)
或者 [shifting](/zh/docs/tasks/traffic-management/traffic-shifting/)。

这提供了另一种创建集群本地流量规则的选择，通过控制到达的目标集群的流量 `VirtualService`：

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: mysvc-cluster-local-vs
spec:
  hosts:
  - mysvc.myns.svc.cluster.local
  http:
  - name: "cluster-1-local"
    match:
    - sourceLabels:
        topology.istio.io/cluster: "cluster-1"
    route:
    - destination:
        host: mysvc.myns.svc.cluster.local
        subset: cluster-1
  - name: "cluster-2-local"
    match:
    - sourceLabels:
        topology.istio.io/cluster: "cluster-2"
    route:
    - destination:
        host: mysvc.myns.svc.cluster.local
        subset: cluster-2
{{< /text >}}

使用这种基于子集的路由方式来控制本地集群流量，但：
[`MeshConfig.serviceSettings`](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ServiceSettings-Settings)
有一个缺点，它把 service-level proxy 和 topology-level proxy 混在了一起。
比如，一个规则发送 10% 的流量给一个服务 `v2` 需要两倍的子集的数量。
 (例如： `cluster-1-v2`, `cluster-2-v2`)。
这个处理方式最好限制在需要对集群的路由进行更多的精细化控制的场景下。

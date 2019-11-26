---
title: 多集群安装
description: 配置跨越多个 Kubernetes 集群的 Istio 服务网格。
weight: 30
aliases:
    - /zh/docs/setup/kubernetes/multicluster-install/
    - /zh/docs/setup/kubernetes/multicluster/
    - /zh/docs/setup/kubernetes/install/multicluster/
keywords: [kubernetes,multicluster]
---

{{< tip >}}
请注意，这些说明不是互斥的。 在由两个以上集群组成的大型多集群部署中，可以使用这些方法的组合。 例如，两个集群可能共享一个控制平面，而第三个集群拥有自己的控制平面。
{{< /tip >}}

欲获取更需信息请参考[多集群部署模型](/zh/docs/ops/prep/deployment-models/#multiple-clusters)。

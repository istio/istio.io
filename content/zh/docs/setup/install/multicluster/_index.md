---
title: 多集群安装
description: 跨多 Kubernetes 集群，安装 Istio 服务网格。
weight: 40
aliases:
    - /zh/docs/setup/kubernetes/multicluster-install/
    - /zh/docs/setup/kubernetes/multicluster/
    - /zh/docs/setup/kubernetes/install/multicluster/
    - /zh/docs/setup/install/multicluster/gateways/
    - /zh/docs/setup/install/multicluster/shared/
keywords: [kubernetes,multicluster]
simple_list: true
content_above: true
test: n/a
owner: istio/wg-environments-maintainers
---
按照本指南安装跨多个集群（{{< gloss "cluster" >}}clusters{{< /gloss >}}） 的
Istio 服务网格（{{< gloss >}}service mesh{{< /gloss >}}）。

本指南的内容涵盖了创建多集群（{{< gloss >}}multicluster{{< /gloss >}}） 网格时最常见的一些问题。

- [网络拓扑](/zh/docs/ops/deployment/deployment-models#network-models):
  一或二个网络

- [控制平面拓扑](/zh/docs/ops/deployment/deployment-models#control-plane-models):
  多主集群（ {{< gloss "primary cluster" >}}primary clusters{{< /gloss >}}）,
  主-从集群（{{< gloss >}}remote cluster{{< /gloss >}}）

{{< tip >}}
对于跨两个以上集群的网格，你可以扩展本指南的步骤，以配置更复杂的拓扑结构。

更多信息，参见[部署模型](/zh/docs/ops/deployment/deployment-models)
{{< /tip >}}

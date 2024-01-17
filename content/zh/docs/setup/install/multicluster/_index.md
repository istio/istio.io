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
test: table-of-contents
owner: istio/wg-environments-maintainers
---
按照本指南安装跨多个{{< gloss "cluster" >}}集群{{< /gloss >}}的
Istio {{< gloss "service mesh" >}}服务网格{{< /gloss >}}。

本指南的内容涵盖了创建{{< gloss "multicluster" >}}多集群{{< /gloss >}}网格时最常见的一些问题。

- [网络拓扑](/zh/docs/ops/deployment/deployment-models#network-models)：
  一或二个网络

- [控制平面拓扑](/zh/docs/ops/deployment/deployment-models#control-plane-models)：
  多{{< gloss "primary cluster" >}}主集群{{< /gloss >}}、
  主{{< gloss "remote cluster" >}}从集群{{< /gloss >}}

{{< tip >}}
对于跨两个以上集群的网格，您可以扩展本指南的步骤，以配置更复杂的拓扑结构。

更多信息，参见[部署模型](/zh/docs/ops/deployment/deployment-models)。
{{< /tip >}}

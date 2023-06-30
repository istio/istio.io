---
title: Deployment 最佳实践
description: 设置 Istio 服务网格时的最佳实践。
force_inline_toc: true
weight: 10
aliases:
  - /zh/docs/ops/prep/deployment
owner: istio/wg-environments-maintainers
test: n/a
---

我们确定了以下大体原则，以帮助您充分利用 Istio Deployment。
这些最佳实践旨在限制不良配置带来的影响，并使 Deployment 管理变得更加轻松。

## 部署较少的集群 {#deploy-fewer-clusters}

应该在少量的大型集群（而不是大量的小型集群）中部署 Istio。
最好的做法是使用[命名空间租赁](/zh/docs/ops/deployment/deployment-models/#namespace-tenancy)来管理大型集群，
而不是将集群添加到 Deployment 中。按照这种方法，您可以在每个区域或区域中的一两个集群上部署 Istio。

然后，您可以在每个区域或区域的一个集群上部署控制平面，以提高可靠性。

## 在靠近用户的地方部署集群 {#deploy-clusters-near-your-users}

在全球部署集群，实现**在地理位置上靠近终端用户**。
这有助于降低 Deployment 的延迟。

## 跨多个可用区域进行部署 {#deploy-across-multiple-availability-zones}

您的 Deployment 中包含在每个地理区域内的**跨多个可用区域**集群。
这种方法可以限制 Deployment{{< gloss "failure domain" >}}故障域{{< /gloss >}}的大小，有助于避免全局故障。

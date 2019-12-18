---
title: 部署的最佳实践
description: 设置 Istion 服务网格时的普遍最佳实践。
force_inline_toc: true
weight: 10
aliases:
  - /zh/docs/ops/prep/deployment
---

我们定义了以下一般性原则来最大化帮助到你的 Istio 部署。
这些最佳实践旨在限制错误的配置变更所带来的影响以及更容易得管理你的部署。

## 部署更少的集群

在少量大型的集群中，而不是在大量的小型集群中部署 Istio。最好的做法是使用 [租户命名空间](/zh/docs/ops/deployment/deployment-models/#namespace-tenancy)来管理大型集群，而不是将集群添加到部署中。按照这种方法，你可以在每个区域或者区域中的一个或两个集群中部署 Istio。你可以在每一个 region 或者 zone 中的集群中部署一个控制平面以提高可靠性。

## 靠近你的用户部署集群

在你的全球化部署中包含集群使得 **终端用户在地理位置上最近**。 邻近性有助于你的部署具有低延迟。

## 跨多个可用区部署

在你的部署中将集群包括在每个地理区域内的多个可用区域和区域中。此方法限制了部署的 {{< gloss "failure domain" >}} 故障域 {{< /gloss >}} 的大小，并且有助于避免全局故障。

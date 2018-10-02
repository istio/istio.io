---
title: 网络运维介绍
description: 介绍 Istio 网络操作方面知识。
weight: 10
---

本节旨在为运维人员提供 Istio 基础部署指南。本节将为 Istio 部署的运维人员提供服务网格管理中网络相关的信息。许多相关的 Istio 文档中已经记录了 Istio 运维人员所需要的步骤和过程，因此本节将在很大程度上依赖这些相关文档。

## Istio 核心概念

在尝试理解，监控或排除 Istio 部署中的网络问题时，从服务网格层面理解基础 Istio 概念是至关重要。服务网格在[架构](/zh/docs/concepts/what-is-istio/#架构)章节中有相关描述。正如架构章节所述，Istio 具有独特的控制平面和数据平面，监控两者的网络状态在运维层面非常重要。服务网格是互相连通代理的集合，代理集合在控制和数据平面中被用来提供 Istio 功能特征。

另一个关键概念是 Istio 如何执行流量管理的。这点在[流量管理介绍](/zh/docs/concepts/traffic-management)章节中有所描述。流量管理功能对外部流入或流出网格以及路由请求提供了细粒度控制。流量管理配置展示了如何处理网格中的微服务之间的请求。有关如何配置流量管理的完整详细介绍，请参见：[流量管理配置](/zh/docs/tasks/traffic-management)。

对于运维人员来讲，最重要的概念是理解 Istio 如何使用网关控制外部流量进入网格或网格内请求访问外部服务。相关配置示例参见：[Istio 网关](/zh/docs/concepts/traffic-management/#gateway)。

## 网格的底层网络

Istio 的服务网格运行在基础设施环境（例如 Kubernetes）网络之上。Istio 对底层网络有一定的要求。由于网络运维存在太多的操作，本指南不会涉及网络层运维细节。 对于 Kubernetes 而言，[Kubernetes Cluster Operator](https://kubernetes.io/docs/user-journeys/users/cluster-operator/foundational/) 是理解容器网络层的一个很好的参考。
Istio 对基础设施底层的网络有以下几点要求：

* Pilot 可发现服务名称到工作负载 IP 的映射（这更像是服务发现要求而不是网络要求）。

* Pilot 服务发现过程可以通过环境中的 API Server 进行。

* 服务端点对 Istio 网格中的所有服务的全部端点 L3 层可达。

* 基础设施的底层网络的防火墙或 ACL 规则不能与任何 Istio 3-7 层流量管理规则冲突。

* 基础设施的底层网络任何防火墙或 ACL 规则都不能与 Istio 控制流量的端口冲突。
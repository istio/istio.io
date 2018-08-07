---
title: 网络操作介绍
description: 介绍 Istio 网络操作方面知识。
weight: 5
---
本节旨在作为 Istio 基础部署运维人员指南。将提供 Istio 部署过程中服务网格管理网络方面的运维所需要的信息。 许多其他的 Istio 文档中已经记录了 Istio 运维人员所需要的步骤和过程，因此本节将在很大程度上依赖这些相关章节。

## Istio 核心理念

在尝试理解，监控或排除 Istio 部署网络问题时，从服务网格层面理解基本 Istio 理念至关重要。 在[架构](/zh/docs/concepts/what-is-istio/#架构)中描述了服务网格。 如架构部分所述，Istio 具有独特的控制平面和数据平面，并且在操作上监控两者的网络状态非常重要。 服务网格是互相连通代理的集合，在控制和数据平面中使用代理来提供 Istio 功能特征。

另一个关键理念是 Istio 如何执行流量管理的。在[流量管理介绍](/zh/docs/concepts/traffic-management)章节总有所描述。流量管理允许对外部流量流入或流出网格以及路由请求提供细粒度控制。 流量管理配置展示了如何处理网格中的微服务之间的请求。 有关如何配置流量管理的完整详细信息，请参见：[流量管理配置](/zh/docs/tasks/traffic-management)。

对运维人员而言必不可少的最后的一个理念是，Istio 如何使用网关控制流量进入网格或网格内的发起的请求访问外部服务。 这里用配置示例对此进行描述：[Istio 网关](/zh/docs/concepts/traffic-management/#gateway)。

## 网格的底层网络

Istio 的服务网格运行在 Istio 网格的基础设施环境（例如 Kubernetes）网络之上。 Istio 对网络层有一定的要求。本指南不会尝试为此网络层提供任何操作细节指导，因为存在太多的选项。 对于 Kubernetes，理解容器网络层的一个很好的参考是 [Kubernetes Cluster Operator](https://kubernetes.io/docs/user-journeys/users/cluster-operator/foundational/)。 

Istio 对底层的网络基础设施有以下要求：

- Pilot 可发现服务名到工作负载 IP 的映射（这更像是服务发现要求而不是网络要求）。
- Pilot 发现过程可以通过特定环境的 API 服务工作。
- 服务端点对 Istio 网格中的服务的所有端点 L3 层可达。
- 基础架构网络层的防火墙或 ACL 规则不能与任何 Istio 3-7 层流量管理规则冲突。
- 基础架构网络层的任何防火墙或 ACL 规则都不能与 Istio 控制流量的端口冲突。
---
title: Istio 服务网格
description: 服务网格。
subtitle: Istio 解决了开发人员和运营商在分布式微服务架构中面临的挑战。无论您是从头构建还是将现有的应用程序迁移到本地云，Istio 都能提供帮助
weight: 34
skip_toc: true
skip_byline: true
skip_pagenav: true
aliases:
    - /zh/service-mesh.html
    - /zh/docs/concepts/what-is-istio/overview
    - /zh/docs/concepts/what-is-istio/goals
    - /zh/about/intro
    - /zh/docs/concepts/what-is-istio/
    - /zh/latest/docs/concepts/what-is-istio/  
doc_type: about
---
[comment]: <> (TODO: Replace Service mesh graphic placeholder)

{{< centered_block >}}
{{< figure src="/img/service-mesh.svg" alt="服务网格" title="通过在部署的每个应用程序中添加代理“sidecar”，Istio 让您可以为应用程序感知流量管理、不可思议的可观察性和强大的安全功能编程到网络中。" >}}
{{< /centered_block >}}

{{< centered_block >}}

## 服务网格介绍{#what-is-a-service-mesh}

现代应用程序通常被设计成微服务的分布式集合，每个服务执行一些离散的业务功能。服务网格是专门的基础设施层，包含了组成这类体系结构的微服务网络。 服务网格不仅描述了这个网络，而且还描述了分布式应用程序组件之间的交互。所有在服务之间传递的数据都由服务网格控制和路由。

随着分布式服务的部署——比如基于 Kubernetes 的系统——规模和复杂性的增长，它可能会变得更加难以理解和管理。需求可以包括发现、负载平衡、故障恢复、度量和监视。微服务体系结构通常还有更复杂的操作需求，比如 A/B 测试、canary 部署、速率限制、访问控制、加密和端到端身份验证。

服务到服务的通信使分布式应用成为可能。在应用程序集群内部和跨应用程序集群路由这种通信变得越来越复杂。 Istio 有助于减少这种复杂性，同时减轻开发团队的压力。
{{< /centered_block >}}

{{< centered_block >}}

## Istio 介绍{#what-is-Istio}

Istio 是一个开源服务网格，它透明地分层到现有的分布式应用程序上。 Istio 强大的特性提供了一种统一和更有效的方式来保护、连接和监视服务。  Istio 是实现负载平衡、服务到服务身份验证和监视的路径——只需要很少或不需要更改服务代码。它强大的控制平面带来了重要的特点，包括：

- 使用 TLS 加密、强身份认证和授权的集群内服务到服务的安全通信
- 自动负载均衡的 HTTP, gRPC, WebSocket，和 TCP 流量
- 通过丰富的路由规则、重试、故障转移和故障注入对流量行为进行细粒度控制
- 一个可插入的策略层和配置 API，支持访问控制、速率限制和配额
- 对集群内的所有流量(包括集群入口和出口)进行自动度量、日志和跟踪

Istio 是为可扩展性而设计的，可以处理不同范围的部署需求。Istio 的控制平面运行在 Kubernetes 上，您可以将部署在该集群中的应用程序添加到您的网格中，将网格扩展到其他集群，甚至连接 VM 或运行在 Kubernetes 之外的其他端点。

一个由贡献者、合作伙伴、集成商和分销商组成的庞大生态系统将 Istio 扩展和利用到各种各样的场景中。

您可以自己安装 Istio，或者许多供应商都有集成 Istio 并为您管理它的产品。
{{< /centered_block >}}

{{< centered_block >}}

## 工作说明{#how-it-works}

Istio 由两个部分组成：控制平面和数据平面。

数据平面是业务之间的通信平面。如果没有一个服务网格，网络就无法理解正在发送的流量，也无法根据它是哪种类型的流量，或者它从谁那里来，到谁那里去做出任何决定。

服务网格使用代理拦截所有的网络流量，允许根据您设置的配置提供广泛的应用程序感知功能。

代理与您在集群中启动的每个服务一起部署，或者与运行在虚拟机上的服务一起运行。

控制平面获取您所需的配置和服务视图，并动态地对代理服务器进行编程，随着规则或环境的变化更新它们。
{{< figure src="/img/service-mesh-before.svg" alt="使用 Istio 前" title="使用 Istio 前" >}}
{{< figure src="/img/service-mesh.svg" alt="使用 Istio 后" title="使用 Istio 后" >}}
{{< /centered_block >}}

# 概念{#concepts}

{{< feature_block header="流量管理" image="management.svg" >}}
Istio 的流量路由规则可以让您轻松地控制服务之间的流量和 API 调用。 Istio 简化了服务级别属性(如断路器、超时和重试)的配置，并使设置重要任务(如 A/B 测试、canary 部署和基于百分比的流量分割的分阶段部署)变得容易。 它还提供了开箱即用的故障恢复特性，帮助您的应用程序更健壮地应对依赖服务或网络的故障。
{{< /feature_block>}}

{{< feature_block header="可观测性" image="observability.svg" >}}
Istio 为服务网格内的所有通信生成详细的遥测数据。这种遥测技术提供了服务行为的可观测性，使运营商能够排除故障、维护和优化其应用。 更好的是，它不会给服务开发人员带来任何额外的负担。通过 Istio，操作人员可以全面了解被监视的服务如何与其他服务以及 Istio 组件本身交互。

Istio 的遥测技术包括详细的指标、分布式跟踪和完整的访问日志。有了 Istio，您就可以得到全面全面的服务网格可观察性。
{{< /feature_block>}}

{{< feature_block header="安全性能" image="security.svg" >}}
微服务有特殊的安全需求，包括防止中间人攻击、灵活的访问控制、审计工具和相互的 TLS。 Istio 包括一个全面的安全解决方案，使运营商能够解决所有这些问题。 它提供了强大的身份、强大的策略、透明的 TLS 加密，以及验证、授权和审计（AAA）工具来保护您的服务和数据。

Istio 的安全模型是基于默认安全的，旨在提供深度防御，允许您部署安全的应用程序，甚至跨不可信的网络。
{{< /feature_block>}}

# 解决方案{#solutions}

{{< solutions_carousel >}}

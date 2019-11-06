---
title: What is Istio?
description: Introduces Istio, the problems it solves, its high-level architecture, and its design goals.
weight: 15
aliases:
    - /zh/docs/concepts/what-is-istio/overview
    - /zh/docs/concepts/what-is-istio/goals
    - /zh/about/intro
---

云平台令使用它们的公司受益匪浅。然而不可否认的是，上云会给DevOps团队带来压力。为了可移植性，开发人员必须使用微服务来构建应用，同时运维人员也正在管理着极端庞大的混合云和多云的部署环境。
Istio允许您连接、保护、控制和观察服务。

从一个较高的层面来说，Istio有助于降低这些部署的复杂性，并减轻开发团队的压力。它是一个完全开源的服务网格，作为透明的一层融入到现有的分布式应用程序里。它也是一个平台，拥有可以集成任何日志、遥测和策略系统的API接口。Istio多样化的特性使您能够成功且高效地运行分布式微服务架构，并提供一种保护、连接和监控微服务的统一方法。

## 什么是服务网格？{#what-is-a-service-mesh}

Istio解决了开发人员和运维人员所面临的从单体应用向分布式微服务架构转变的挑战。了解如何做到这一点可以让我们更详细地理解Istio的服务网格。

术语服务网格用来描述组成这些应用程序的微服务网络以及它们之间的交互。随着服务网格的规模和复杂性不断的增长，它将会变得越来越难以理解和管理。它的需求可以包括发现、负载均衡、故障恢复、指标和监控。一个服务网格通常还有更复杂的操作需求，比如A/B测试、金丝雀发布、速率限制、访问控制和端到端认证。

Istio提供了对整个服务网格的行为洞察和操作控制的能力，以及一个完整的解决方案来满足微服务应用的各种需求。

## 为什么使用Istio？{#why-use-istio}

通过负载均衡、服务到服务的身份验证、监控等方法，Istio可以轻松地创建一个已经部署了服务的网络，而服务的代码更改[很少](/zh/docs/tasks/observability/distributed-tracing/overview/#trace-context-propagation) 或者无需更改。通过在整个环境中部署一个特殊的sidecar代理为服务添加Istio的支持，而代理会拦截微服务之间的所有网络通信，然后使用其控制平面的功能来配置和管理Istio，这包括：

* 为HTTP、gRPC、WebSocket和TCP流量自动负载均衡。

* 通过丰富的路由规则、重试、故障转移和故障注入对流量行为进行细粒度控制。

* 可插拔的策略层和配置API，支持访问控制、速率限制和配额。

* 集群内所有流量的自动话度量、日志和追踪，包括集群入口和出口。

* 在具有强大的基于身份验证和授权的集群中实现安全的服务到服务间通信。

Istio为可扩展性而设计，可以满足不同的部署需求。

## 核心特性{#core-features}

Istio以统一的方式提供了许多跨服务网络的关键功能：

### 流量管理{#traffic-management}

Istio简单的规则配置和流量路由允许您控制服务之间的流量和API调用过程。Istio简化了服务级属性（如熔断器、超时和重试）的配置，并且让它轻而易举的执行重要的任务（如A/B测试、金丝雀发布和按流量百分比划分的分阶段发布）。

有了更好的对流量的可视性和开箱即用的故障恢复特性，您就可以在问题产生之前捕获它们，无论面对什么情况，使您的调用更可靠，网络更健壮。

请参考 [流量管理概念手册](/docs/concepts/traffic-management/) 获取更多细节。

### 安全{#security}

Istio’s security capabilities free developers to focus on security at the application level. Istio provides the underlying secure communication channel, and
manages authentication, authorization, and encryption of service communication at scale. With Istio, service communications are secured by default,
letting you enforce policies consistently across diverse protocols and runtimes -- all with little or no application changes.

While Istio is platform independent, using it with Kubernetes (or infrastructure) network policies, the benefits are even greater, including the ability to
secure {{<gloss>}}pod{{</gloss>}}-to-pod or service-to-service communication at the network and application layers.

Refer to the [Security concepts guide](/docs/concepts/security/) for more details.

### 策略{#policies}

Istio lets you configure custom policies for your application to enforce rules at runtime such as:

* Rate limiting to dynamically limit the traffic to a service
* Denials, whitelists, and blacklists, to restrict access to services
* Header rewrites and redirects

Istio also lets you create your own [policy adapters](/docs/tasks/policy-enforcement/control-headers) to add, for example, your own custom authorization behavior.

Refer to the [Policies concepts guide](/docs/concepts/policies/) for more details.

### 可观察性{#observability}

Istio’s robust tracing, monitoring, and logging features give you deep insights into your service mesh deployment. Gain a real understanding of how service performance
impacts things upstream and downstream with Istio’s monitoring features, while its custom dashboards provide visibility into the performance of all your
services and let you see how that performance is affecting your other processes.

Istio’s Mixer component is responsible for policy controls and telemetry collection. It provides backend abstraction and intermediation, insulating the rest of
Istio from the implementation details of individual infrastructure backends, and giving operators fine-grained control over all interactions between the mesh
and infrastructure backends.

All these features let you more effectively set, monitor, and enforce SLOs on services. Of course, the bottom line is that you can detect and fix issues quickly
and efficiently.

Refer to the [Observability concepts guide](/docs/concepts/observability/) for more details.

## 平台支持{#platform-support}

Istio is platform-independent and designed to run in a variety of environments, including those spanning Cloud, on-premise, Kubernetes, Mesos, and more. You can
 deploy Istio on Kubernetes, or on Nomad with Consul. Istio currently supports:

* Service deployment on Kubernetes

* Services registered with Consul

* Services running on individual virtual machines

## 整合和定制{#integration-and-customization}

The policy enforcement component of Istio can be extended and customized to integrate with existing solutions for ACLs, logging, monitoring, quotas, auditing,
and more.

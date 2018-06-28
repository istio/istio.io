---
title: 概述
description: 提供 Istio 的概念介绍，包括其解决的问题和宏观架构。
weight: 15
---

本文档介绍了 Istio——一个用来连接、管理和保护微服务的开放平台。Istio 提供一种简单的方式来建立已部署的服务网络，该服务网格具有负载均衡、服务间认证、监控等功能，而不需要改动任何服务代码。想要为服务增加对 Istio 的支持，您只需要在环境中部署一个特殊的 sidecar，使用 Istio 控制面板功能配置和管理代理，拦截微服务之间的所有网络通信。

Istio 目前支持在 Kubernetes 上的服务部署，还支持使用 Consul 或 Eureka 做服务注册，服务可以运行在虚拟机上。

有关Istio组件的详细概念信息，请参阅我们的其他[概念](/docs/concepts/)指南。

## 为什么要使用Istio？

在从单体应用程序向分布式微服务架构的转型过程中，开发人员和运维人员面临诸多挑战，使用 Istio 可以解决这些问题。术语**服务网格（Service Mesh）**通常用于描述构成这些应用程序的微服务网络以及它们之间的交互。随着规模和复杂性的增长，服务网格越来越难以理解和管理。它的需求包括服务发现、负载均衡、故障恢复、指标收集和监控以及通常更加复杂的运维需求，例如 A/B 测试、金丝雀发布、限流、访问控制和端到端认证等。

Istio 提供了一个完整的解决方案，通过为整个服务网格提供行为洞察和操作控制来满足微服务应用程序的多样化需求。它在服务网络中统一提供了许多关键功能：

- **流量管理**。控制服务之间的流量和API调用的流向，使得调用更可靠，并使网络在恶劣情况下更加健壮。
- **服务身份和安全**。为网格中的服务提供可验证身份，并提供保护服务流量的能力，使其可以在不同可信度的网络上流转。
- **策略执行**。将组织策略应用于服务之间的互动，确保访问策略得以执行，资源在消费者之间良好分配。可以通过通过配置网格而不是修改应用程序代码来完成策略的更改。
- **遥测**：了解服务之间的依赖关系，以及它们之间流量的本质和流向，从而提供快速识别问题的能力。

除此之外，Istio 针对可扩展性进行了设计，以满足不同的部署需要：

- **平台支持**。Istio 旨在可以在各种环境中运行，包括跨云、预置环境、Kubernetes、Mesos 等。最初专注于 Kubernetes，但很快将支持其他环境。
- **集成和定制**。策略执行组件可以扩展和定制，以便与现有的 ACL、日志、监控、配额、审计等解决方案集成。

这些功能极大的减少了应用程序代码，底层平台和策略之间的耦合。耦合的减少不仅使服务更容易实现，而且还使运维人员更容易地在环境之间移动应用程序部署，或换用新的策略方案。因此，结果就是应用程序从本质上变得更容易移动。

## 架构

Istio服务网格逻辑上分为**数据面板**和**控制面板**。

- **数据面板**由一组智能代理（Envoy）组成，代理部署为 sidecar，调节和控制微服务之间所有的网络通信。
- **控制面板**负责管理和配置代理来路由流量，以及在运行时执行策略。

下图显示了构成每个面板的不同组件：

{{< image width="80%" ratio="56.25%"
    link="/docs/concepts/what-is-istio/overview/arch.svg"
    alt="基于 Istio 的应用程序架构概览"
    caption="Istio 架构"
    >}}

### Envoy

Istio 使用 [Envoy](https://www.envoyproxy.io/) 代理的扩展版本，Envoy 是以 C ++ 开发的高性能代理，用于调解服务网格中所有服务的所有入站和出站流量。Envoy 的许多内置功能被 istio 发扬光大，例如动态服务发现、负载均衡、TLS终止、HTTP/2 & gRPC 代理、熔断器、健康检查、基于百分比流量拆分的分段推出以及故障注入和丰富的度量指标。

Envoy 被部署为 **sidecar**，和对应服务在同一个 Kubernetes pod 中。这允许 Istio 将大量关于流量行为的信号作为[属性](/docs/concepts/policies-and-telemetry/config/#attributes)提取出来，而这些属性又可以在 [Mixer](/docs/concepts/policies-and-telemetry/overview/) 中用于执行策略决策，并发送给监控系统，以提供整个网格行为的信息。Sidecar 代理模型还可以将 Istio 的功能添加到现有部署中，而无需重新构建或重写代码。可以阅读更多来了解为什么我们在[设计目标](/docs/concepts/what-is-istio/goals/)中选择这种方式。

### Mixer

[Mixer](/docs/concepts/policies-and-telemetry/overview) 是一个独立于平台的组件，负责在服务网格上执行访问控制和使用策略，并从 Envoy 代理和其他服务收集遥测数据。代理提取请求级[属性](/docs/concepts/policies-and-telemetry/config/#attributes)，发送到 Mixer 进行评估。有关属性提取和策略评估的更多信息，请参见 [Mixer 配置](/docs/concepts/policies-and-telemetry/config)。Mixer 包括一个灵活的插件模型，使其能够接入到各种主机环境和基础设施后端，从这些细节中抽象出 Envoy 代理和 Istio管理的服务。

### Pilot

[Pilot](/docs/concepts/traffic-management/pilot/) 为 Envoy sidecar 提供服务发现功能，为智能路由（例如 A/B 测试、金丝雀部署等）和弹性（超时、重试、断路器等）提供流量管理功能。它将控制流量行为的高级路由规则转换为特定于 Envoy 的配置，并在运行时将它们传播到 sidecar。Pilot 将平台特定的服务发现机制抽象化并将其合成为符合 [Envoy 数据平面 API](https://github.com/envoyproxy/data-plane-api) 的任何 sidecar 都可以使用的标准格式。这种松散耦合使得 Istio 能够在多种环境下运行（例如，Kubernetes、Consul/Nomad），同时保持用于流量管理的相同操作界面。

### Citadel

[Citadel](/docs/concepts/security/) 通过内置身份和凭证管理可以提供强大的服务间和最终用户身份验证。可用于升级服务网格中未加密的流量，并为运维人员提供基于服务标识而不是网络控制的强制执行策略的能力。从 0.5 版本开始，Istio 支持[基于角色的访问控制](/docs/concepts/security/rbac/)，以控制谁可以访问您的服务。

## 下一步

- 了解 Istio 的[设计目标](/docs/concepts/what-is-istio/goals/)。
- 探索我们的[指南](/docs/examples/)。
- 在我们其他的[概念](/docs/concepts/)指南中详细了解 Istio 组件。
- 使用我们的[任务](/docs/tasks/)指南，了解如何将自己的服务部署到 Istio。

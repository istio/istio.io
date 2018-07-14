---
title: Istio 是什么?
description: 介绍 Istio 及其要解决的问题、顶层架构和设计目标。
weight: 15
aliases:
    - /docs/concepts/what-is-istio/overview
    - /docs/concepts/what-is-istio/goals
    - /about/intro
---

Istio 是一个用来连接、管理和保护微服务的开放平台。

Istio 提供一种简单的方式来为已部署的服务建立网络，该网络具有负载均衡、服务间认证、监控等功能，而不需要对服务的代码做任何改动。想要让服务支持 Istio，只需要在您的环境中部署一个特殊的 sidecar，使用 Istio 控制平面功能配置和管理代理，拦截微服务之间的所有网络通信。

* HTTP、gRPC、WebSocket 和 TCP 流量的自动负载均衡。
* 通过丰富的路由规则、重试、故障转移和故障注入，可以对流量行为进行细粒度控制。
* 可插入的策略层和配置 API，支持访问控制、速率限制和配额。
* 对出入集群入口和出口中所有流量的自动度量指标、日志记录和跟踪。
* 通过强大的基于身份的验证和授权，在集群中实现安全的服务间通信。

您可以在 [Kubernetes](https://kubernetes.io) 上，或者在含有 [Consul](https://nomadproject.io) 的 [Nomad](https://nomadproject.io) 集群中部署 Istio。我们计划在不久的将来增加对 [Cloud Foundry](https://www.cloudfoundry.org/) 和 [Apache Mesos](https://www.cloudfoundry.org/) 等其他平台的支持。

Istio 目前支持：

* 部属在 Kubernetes 上的服务
* 在 Consul 中注册的服务
* 在虚拟机上运行的服务

## 为什么要使用 Istio？

在从单体应用程序向分布式微服务架构的转型过程中，开发人员和运维人员面临诸多挑战，使用 Istio 可以解决这些问题。**服务网格（Service Mesh）**这个术语通常用于描述构成这些应用程序的微服务网络以及应用之间的交互。随着规模和复杂性的增长，服务网格越来越难以理解和管理。它的需求包括服务发现、负载均衡、故障恢复、指标收集和监控以及通常更加复杂的运维需求，例如 A/B 测试、金丝雀发布、限流、访问控制和端到端认证等。

Istio 提供了一个完整的解决方案，通过为整个服务网格提供行为洞察和操作控制来满足微服务应用程序的多样化需求。它在服务网络中统一提供了许多关键功能：

* **流量管理**。控制服务之间的流量和API调用的流向，使得调用更可靠，并使网络在恶劣情况下更加健壮。
* **服务身份和安全**。为网格中的服务提供可验证身份，并提供保护服务流量的能力，使其可以在不同可信度的网络上流转。
* **策略执行**。将组织策略应用于服务之间的互动，确保访问策略得以执行，资源在消费者之间良好分配。可以通过通过配置网格而不是修改应用程序代码来完成策略的更改。
* **遥测**：了解服务之间的依赖关系，以及它们之间流量的本质和流向，从而提供快速识别问题的能力。

除此之外，Istio 针对可扩展性进行了设计，以满足不同的部署需要：

* **平台支持**。Istio 旨在可以在各种环境中运行，包括跨云、预置环境、Kubernetes、Mesos 等。最初专注于 Kubernetes，但很快将支持其他环境。
* **集成和定制**。策略执行组件可以扩展和定制，以便与现有的 ACL、日志、监控、配额、审计等方案集成。

这些功能极大的减少了应用程序代码、底层平台以及策略之间的耦合。耦合减少了不仅让可以让我们更容易的实现服务，而且能够让运维人员在不同的环境之间迁移部署的应用程序，或换用新的策略方案。因此，应用程序本身将更具可移植性。

## 架构

Istio 服务网格逻辑上分为**数据平面**和**控制平面**。

* **数据平面**由一组以 sidecar 方式部署的智能代理（[Envoy](https://www.envoyproxy.io/)）组成。这些代理可以调节和控制微服务及 [Mixer](/docs/concepts/policies-and-telemetry/) 之间所有的网络通信。
* **控制平面**负责管理和配置代理来路由流量。此外控制平面配置 Mixer 以实施策略和收集遥测数据。

下图显示了构成每个面板的不同组件：

{{< image width="80%" ratio="56.25%"
    link="/docs/concepts/what-is-istio/arch.svg"
    alt="基于 Istio 的应用程序架构概览"
    caption="Istio 架构"
    >}}

### Envoy

Istio 使用 [Envoy](https://www.envoyproxy.io/) 代理的扩展版本，Envoy 是以 C++ 开发的高性能代理，用于调解服务网格中所有服务的所有入站和出站流量。Envoy 的许多内置功能被 istio 发扬光大，例如：

* 动态服务发现
* 负载均衡
* TLS 终止
* HTTP/2 & gRPC 代理
* 熔断器
* 健康检查、基于百分比流量拆分的灰度发布
* 故障注入
* 丰富的度量指标

Envoy 被部署为 **sidecar**，和对应服务在同一个 Kubernetes pod 中。这允许 Istio 将大量关于流量行为的信号作为[属性](/docs/concepts/policies-and-telemetry/#attributes)提取出来，而这些属性又可以在 [Mixer](/docs/concepts/policies-and-telemetry/) 中用于执行策略决策，并发送给监控系统，以提供整个网格行为的信息。

Sidecar 代理模型还可以将 Istio 的功能添加到现有部署中，而无需重新构建或重写代码。可以阅读更多来了解为什么我们在[设计目标](/docs/concepts/what-is-istio/#design-goals)中选择这种方式。

### Mixer

[Mixer](/docs/concepts/policies-and-telemetry/) 是一个独立于平台的组件，负责在服务网格上执行访问控制和使用策略，并从 Envoy 代理和其他服务收集遥测数据。代理提取请求级[属性](/docs/concepts/policies-and-telemetry/#attributes)，发送到 Mixer 进行评估。有关属性提取和策略评估的更多信息，请参见 [Mixer 配置](/docs/concepts/policies-and-telemetry/#configuration-model)。

Mixer 中包括一个灵活的插件模型，使其能够接入到各种主机环境和基础设施后端，从这些细节中抽象出 Envoy 代理和 Istio 管理的服务。

### Pilot

[Pilot](/docs/concepts/traffic-management/#pilot-and-envoy) 为 Envoy sidecar 提供服务发现功能，为智能路由（例如 A/B 测试、金丝雀部署等）和弹性（超时、重试、熔断器等）提供流量管理功能。它将控制流量行为的高级路由规则转换为特定于 Envoy 的配置，并在运行时将它们传播到 sidecar。

Pilot 将平台特定的服务发现机制抽象化并将其合成为符合 [Envoy 数据平面 API](https://github.com/envoyproxy/data-plane-api) 的任何 sidecar 都可以使用的标准格式。这种松散耦合使得 Istio 能够在多种环境下运行（例如，Kubernetes、Consul、Nomad），同时保持用于流量管理的相同操作界面。

### Citadel

[Citadel](/docs/concepts/security/) 通过内置身份和凭证管理可以提供强大的服务间和最终用户身份验证。可用于升级服务网格中未加密的流量，并为运维人员提供基于服务标识而不是网络控制的强制执行策略的能力。从 0.5 版本开始，Istio 支持[基于角色的访问控制](/docs/concepts/security/#role-based-access-control-rbac)，以控制谁可以访问您的服务。

## 设计目标

Istio 的架构设计中有几个关键目标，这些目标对于使系统能够应对大规模流量和高性能地服务处理至关重要。

* **最大化透明度**：若想 Istio 被采纳，应该让运维和开发人员只需付出很少的代价就可以从中受益。为此，Istio 将自身自动注入到服务间所有的网络路径中。Istio 使用 sidecar 代理来捕获流量，并且在尽可能的地方自动编程网络层，以路由流量通过这些代理，而无需对已部署的应用程序代码进行任何改动。在 Kubernetes中，代理被注入到 pod 中，通过编写 iptables 规则来捕获流量。注入 sidecar 代理到 pod 中并且修改路由规则后，Istio 就能够调解所有流量。这个原则也适用于性能。当将 Istio 应用于部署时，运维人员可以发现，为提供这些功能而增加的资源开销是很小的。所有组件和 API 在设计时都必须考虑性能和规模。

* **增量**：随着运维人员和开发人员越来越依赖 Istio 提供的功能，系统必然和他们的需求一起成长。虽然我们期望继续自己添加新功能，但是我们预计最大的需求是扩展策略系统，集成其他策略和控制来源，并将网格行为信号传播到其他系统进行分析。策略运行时支持标准扩展机制以便插入到其他服务中。此外，它允许扩展词汇表，以允许基于网格生成的新信号来执行策略。

* **可移植性**：使用 Istio 的生态系统将在很多维度上有差异。Istio 必须能够以最少的代价运行在任何云或预置环境中。将基于 Istio 的服务移植到新环境应该是轻而易举的，而使用 Istio 将一个服务同时部署到多个环境中也是可行的（例如，在多个云上进行冗余部署）。

* **策略一致性**：在服务间的 API 调用中，策略的应用使得可以对网格间行为进行全面的控制，但对于无需在 API 级别表达的资源来说，对资源应用策略也同样重要。例如，将配额应用到 ML 训练任务消耗的 CPU 数量上，比将配额应用到启动这个工作的调用上更为有用。因此，策略系统作为独特的服务来维护，具有自己的 API，而不是将其放到代理/sidecar 中，这容许服务根据需要直接与其集成。

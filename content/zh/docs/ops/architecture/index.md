---
title: 架构
description: 描述 Istio 的整体架构与设计目标。
weight: 20
aliases:
- /zh/docs/concepts/architecture

---

Istio 服务网格从逻辑上分为数据平面和控制平面。

- **数据平面**由一组智能代理（[Envoy](https://www.envoyproxy.io/)）组成，被部署为 sidecar。这些代理通过一个通用的策略和遥测中心（[Mixer](/zh/docs/reference/config/policy-and-telemetry/)）传递和控制微服务之间的所有网络通信。
- **控制平面**管理并配置代理来进行流量路由。此外，控制平面配置 Mixer 来执行策略和收集遥测数据。

下图展示了组成每个平面的不同组件：

{{< image width="80%" link="./arch.svg" alt="Istio 应用的整体架构。" caption="Istio 架构" >}}

Istio 中的流量分为数据平面流量和控制平面流量。数据平面流量是指工作负载的业务逻辑发送和接收的消息。控制平面流量是指在 Istio 组件之间发送的配置和控制消息用来编排网格的行为。Istio 中的流量管理特指数据平面流量。

## 组件{#components}

以下各节概述了 Istio 的每个核心组件。

### Envoy{#envoy}

Istio 使用 [Envoy](https://envoyproxy.github.io/envoy/) 代理的扩展版本。Envoy 是用 C++ 开发的高性能代理，用于协调服务网格中所有服务的入站和出站流量。Envoy 代理是唯一与数据平面流量交互的 Istio 组件。

Envoy 代理被部署为服务的 sidecar，在逻辑上为服务增加了 Envoy 的许多内置特性，例如:

- 动态服务发现
- 负载均衡
- TLS 终端
- HTTP/2 与 gRPC 代理
- 熔断器
- 健康检查
- 基于百分比流量分割的分阶段发布
- 故障注入
- 丰富的指标

这种 sidecar 部署允许 Istio 提取大量关于流量行为的信号作为[属性](/zh/docs/reference/config/policy-and-telemetry/mixer-overview/#attributes)。反之，Istio 可以在 [Mixer](/zh/docs/reference/config/policy-and-telemetry/) 中使用这些属性来执行决策，并将它们发送到监控系统，以提供整个网格的行为信息。

sidecar 代理模型还允许您向现有的部署添加 Istio 功能，而不需要重新设计架构或重写代码。您可以在[设计目标](#design-goals)中读到更多关于为什么我们选择这种方法的信息。

由 Envoy 代理启用的一些 Istio 的功能和任务包括:

- 流量控制功能：通过丰富的 HTTP、gRPC、WebSocket 和 TCP 流量路由规则来执行细粒度的流量控制。
- 网络弹性特性：重试设置、故障转移、熔断器和故障注入。
- 安全性和身份验证特性：执行安全性策略以及通过配置API定义的访问控制和速率限制。

### Mixer{#mixer}

[Mixer](/zh/docs/reference/config/policy-and-telemetry/) 是一个平台无关的组件。Mixer 在整个服务网格中执行访问控制和策略使用，并从 Envoy 代理和其他服务收集遥测数据。代理提取请求级别[属性](/zh/docs/reference/config/policy-and-telemetry/mixer-overview/#attributes)，并将其发送到 Mixer 进行评估。您可以在我们的 [Mixer 配置文档](/zh/docs/reference/config/policy-and-telemetry/mixer-overview/#configuration-model)中找到更多关于属性提取和策略评估的信息。

Mixer 包括一个灵活的插件模型。该模型使 Istio 能够与各种主机环境和后端基础设施进行交互。因此，Istio 从这些细节中抽象出 Envoy 代理和 Istio 管理的服务。

### Pilot{#pilot}

Pilot 为 Envoy sidecar 提供服务发现、用于智能路由的流量管理功能（例如，A/B 测试、金丝雀发布等）以及弹性功能（超时、重试、熔断器等）。

Pilot 将控制流量行为的高级路由规则转换为特定于环境的配置，并在运行时将它们传播到 sidecar。Pilot 将特定于平台的服务发现机制抽象出来，并将它们合成为任何符合 [Envoy API](https://www.envoyproxy.io/docs/envoy/latest/api/api) 的 sidecar 都可以使用的标准格式。

下图展示了平台适配器和 Envoy 代理如何交互。

{{< image width="40%" link="./discovery.svg" caption="Service discovery" >}}

1. 平台启动一个服务的新实例，该实例通知其平台适配器。
1. 平台适配器使用 Pilot 抽象模型注册实例。
1. **Pilot** 将流量规则和配置派发给 Envoy 代理，来传达此次更改。

这种松耦合允许 Istio 在 Kubernetes、Consul 或 Nomad 等多种环境中运行，同时维护相同的 operator 接口来进行流量管理。

您可以使用 Istio 的[流量管理 API](/zh/docs/concepts/traffic-management/#introducing-istio-traffic-management) 来指示 Pilot 优化 Envoy 配置，以便对服务网格中的流量进行更细粒度地控制。

### Citadel{#citadel}

[Citadel](/zh/docs/concepts/security/) 通过内置的身份和证书管理，可以支持强大的服务到服务以及最终用户的身份验证。您可以使用 Citadel 来升级服务网格中的未加密流量。使用Citadel，operator 可以执行基于服务身份的策略，而不是相对不稳定的3层或4层网络标识。从0.5版开始，您可以使用 [Istio 的授权特性](/zh/docs/concepts/security/#authorization)来控制谁可以访问您的服务。

### Galley{#galley}

Galley 是 Istio 的配置验证、提取、处理和分发组件。它负责将其余的 Istio 组件与从底层平台（例如 Kubernetes）获取用户配置的细节隔离开来。

## 设计目标{#design-goals}

几个关键的设计目标形成了 Istio 的架构。这些目标对于使系统能够大规模和高性能地处理服务是至关重要的。

- **透明度最大化**：为了采用 Istio，运维人员或开发人员需要做尽可能少的工作，才能从系统中获得真正的价值。为此，Istio 可以自动将自己注入到服务之间的所有网络路径中。Istio 使用 sidecar 代理来捕获流量，并在可能的情况下，在不更改已部署的应用程序代码的情况下，自动对网络层进行配置，以实现通过这些代理来路由流量。在 Kubernetes 中，代理被注入到{{<gloss pod>}}pods{{</gloss>}}中，通过编写‘iptables’规则来捕获流量。一旦 sidecar 代理被注入以及流量路由被编程，Istio 就可以协调所有的流量。这个原则也适用于性能。当将 Istio 应用于部署时，运维人员会看到所提供功能的资源成本增加地最小。组件和 API 的设计必须考虑到性能和可伸缩性。
- **可扩展性**：随着运维人员和开发人员越来越依赖于 Istio 提供的功能，系统必须随着他们的需求而增长。当我们继续添加新特性时，最大的需求是扩展策略系统的能力，与其他策略和控制源的集成，以及将关于网格行为的信号传播到其他系统进行分析的能力。策略运行时支持用于接入其他服务的标准扩展机制。此外，它允许扩展其词汇表，允许根据网格生成的新信号执行策略。
- **可移植性**：使用 Istio 的生态系统在许多方面都有所不同。Istio 必须在任何云环境或本地环境中通过最小的努力就能运行起来。将基于 Istio 的服务移植到新环境的任务必须是容易实现的。使用 Istio，您可以操作部署到多个环境中的单个服务。例如，可以在多个云上部署来实现冗余。
- **策略一致性**：将策略应用于服务之间的API调用提供了对网格行为的大量控制。然而，将策略应用在区别于 API 层上的资源也同样重要。例如，在机器学习训练任务消耗的 CPU 数量上应用配额比在发起任务的请求调用上应用配额更有用。为此，Istio 使用自己的 API 将策略系统维护为一个独立的服务，而不是将策略系统集成到 sidecar 代理中，从而允许服务根据需要直接与之集成。

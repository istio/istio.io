---
title: "在 Istio 中扩展网关 API 的支持"
description: "服务网格的标准 API，将在 Istio 和更广泛的社区中运用。"
publishdate: 2022-07-13
attribution: "Craig Box (Google)"
keywords: [traffic-management,gateway,gateway-api,api,gamma,sig-network]
---

今天我们要 [祝贺 Kubernetes SIG Network 社区发布了 Gateway API 规范的 beta 版本](https://kubernetes.io/blog/2022/07/13/gateway-api-graduates-to-beta/)。
除了上述的这个里程碑，我们很高兴地宣布，对在 Istio ingress 中使用 Gateway API 的支持正在升级为 Beta版本，
并且我们打算让 Gateway API 成为未来所有 Istio 流量管理的默认 API。
我们也很高兴地欢迎来自服务网格接口（SMI）社区的朋友，他们将加入我们的行列，并使用网关 API 来标准化服务网格用例。

## Istio 流量管理 API 的历史{#the-history-of-istios-traffic-management-apis}

API 设计与其说是一门科学，不如说是一门艺术，Istio 经常被用作一个 API 来配置其他 API 的服务！
仅在流量路由的情况下，我们必须考虑生产者与消费者、路由与被路由，以及如何使用正确数量的对象来表达复杂的特征集——考虑到这些对象必须由不同的团队拥有。

当我们在 2017 年推出 Istio 时，我们从 Google 的生产 API 服务基础设施和 IBM 的 Amalgam8 项目的多年经验带到了 Kubernetes 上。
我们很快就遇到了 Kubernetes 的 Ingress API 的限制。支持所有代理实现的愿望意味着 Ingress 仅支持最基本的 HTTP 路由功能，
而其他功能通常作为供应商特定的注释来实现。Ingress API在基础设施管理员 （"创建和配置负载均衡器"），
集群 Operator（"为我的整个域管理 TLS 证书"）和应用程序用户（“使用它将 /foo 路由到 foo 服务”）之间共享。

我们[在 2018 年初重写了流量 API](/zh/blog/2018/v1alpha3-routing/) 以解决用户反馈问题，并更充分地解决这些问题。

Istio 新模式的一个主要特性是具有单独的 API 来描述基础设施(负载均衡器，由 [Gateway](/zh/docs/concepts/traffic-management/#gateways) 表示）和应用程序（路由和被路由，由 [VirtualService](/zh/docs/concepts/traffic-management/#virtual-services) 和 [DestinationRule](/zh/docs/concepts/traffic-management/#destination-rules) 表示）。

Ingress 实施方案之间的最低共同标准运作良好，但它的缺点导致 SIG Network 研究了“第 2 版本”的设计。在[2018 年的一次用户调查](https://github.com/bowei/k8s-ingress-survey-2018/blob/master/survey.pdf)之后，[在 2019 年提出了一个新的 API 建议](https://www.youtube.com/watch?v=Ne9UJL6irXY)，在很大程度上是基于 Istio 的流量 API。这种设计后来被称为“网关 API”。

Gateway API 的构建是为了能够对更多用例进行建模，并通过扩展点来启用不同实现之间的功能。此外，采用 Gateway API 可以使服务网格与为支持它而编写的整个软件生态系统兼容。您不需要要求您的供应商直接支持 Istio 路由：他们需要做的就是创建 Gateway API 对象，而 Istio 会做它需要做的事情，开箱即用。

## 支持 Istio 中的网关 API{#support-for-the-gateway-api-in-istio}

Istio 在 2020 年 11 月增加了[对 Gateway API 的支持](/zh/docs/tasks/traffic-management/ingress/gateway-api/),支持标记为 Alpha 以及 API 的实现。随着 API 规范的 Beta 版发布，我们很高兴地宣布 Istio 中对 ingress 使用的支持正在升级为 Beta 。我们还鼓励早期采用者开始试验用于网格(服务到服务)使用的 Gateway API，当 SIG Network 标准化所需的语义时，我们会将这种支持转移到 Beta 版。

在 API 的 v1 版本发布时，我们打算让 Gateway API 成为配置 Istio 中所有流量路由的默认方法-用于入口(南北)和服务到服务(东西)。届时，我们将更改我们的文档和示例以反映该建议。

就像 Kubernetes 打算在 Gateway API 稳定后支持 Ingress API 很多年一样，Istio API (Gateway, VirtualService 和 DestinationRule)在可预见的未来仍将保持支持。

不仅如此，您还可以继续使用现有的 Istio 流量 API 和 Gateway API，例如，使用带有 [HTTPRoute](https://gateway-api.sigs.k8s.io/v1beta1/api-types/httproute/) 和 Istio [VirtualService](/zh/docs/reference/config/networking/virtual-service/).

API 之间的相似性意味着我们将能够提供一个工具来轻松地将 Istio API 对象转换为 Gateway API 对象，我们将与 API 的 v1 版本一起发布。

Istio 功能的其他部分，包括策略和遥测，将继续使用 Istio 特定的 API 进行配置，同时我们与 SIG Network 合作，对这些用例进行标准化。

## 欢迎 SMI 社区加入 Gateway API 项目{#welcoming-the-smi-community-to-the-gateway-api-project}

在整个设计和实施过程中，Istio 团队的成员一直在与 SIG Network 的成员合作构建网关 API，以确保该 API 适用于网格用例。

我们很高兴服务网格接口（SMI）社区的成员[正式加入这项工作](https://smi-spec.io/blog/announcing-smi-gateway-api-gamma)，包括来自 Linkerd、Consul 和 Open Service Mesh 的领导者，他们共同决定在 Gateway API 上标准化他们的 API 工作。为此，我们已经在 Gateway API 项目中建立了 [Gateway API Mesh Management and Administration (GAMMA) 工作流](https://gateway-api.sigs.k8s.io/contributing/gamma/)。John Howard 是 Istio 技术监督委员会的成员，也是我们网络工作组的负责人，他将成为这个小组的负责人。

我们接下来的联合步骤是为网关 API 项目提供[增强建议](https://gateway-api.sigs.k8s.io/v1alpha2/contributing/gep/)，以确保该 API 适用于网格用例。我们已经[开始关注 API 语义](https://docs.google.com/document/d/1T_DtMQoq2tccLAtJTpo3c0ohjm25vRS35MsestSL9QU/edit)用于网格流量管理的问题，并将与在其项目中实施 Gateway API 的供应商和社区合作，以建立一个标准实施。之后，我们打算为授权和身份验证策略构建一个表示。

SIG Network 作为供应商中立论坛，确保服务网格社区使用相同的语义来实现网关 API，我们期待有一个标准 API ，它适用于所有的项目，无论其使用任何技术栈或代理软件。

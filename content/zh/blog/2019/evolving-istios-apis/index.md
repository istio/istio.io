---
title: "Istio API 的演变"
description: "Istio API 的设计原则和这些 API 是如何演变的。"
publishdate: 2019-08-05
attribution: Louis Ryan (Google), Sandeep Parikh (Google)
keywords: [apis,composability,evolution]
target_release: 1.2
---

使团队能开发出最适合他们特定组织或者工作负载的抽象层，是 Istio 的一个主要目标，过去是，将来也是。Istio 为服务与服务之间网络通信提供了健壮有力的模块。从 [Istio 0.1](/zh/news/releases/0.x/announcing-0.1) 开始，Istio 小组一直在从生产用户那里了解他们如何将自己的架构、工作负载和约束映射到 Istio 的功能，并且一直在持续优化 Istio API 来让它们更好地为用户服务。

## Istio API 的演变{#evolving-Istio-APIs}

Istio API 进化的下一步重心是在 Istio 用户的角色上。一个安全管理员应该能够与在逻辑上分组并且简化 Istio 网格中安全操作的 API 进行交互；服务操作人员和流量管理操作也是如此。

更进一步，使我们有机会为每个角色的初级、中级、高级用例提供改进的体验。有许多常见的用例，可以通过显而易见的默认的设置和一个需要极少配置甚至不需要配置的更好定义的初始体验来解决。对于中级用例，Istio 小组希望利用环境中的上下文提示来为你提供一个更简便的配置体验。最后，对于更高级的使用场景，我们的目标是[让简单的事简单困难的事成为可能](https://www.quora.com/What-is-the-origin-of-the-phrase-make-the-easy-things-easy-and-the-hard-things-possible)。

为了提供这些以角色为中心的抽象，无论如何，在这些抽象之下的 API 必须要能够描述 Istio 的所有功能。从历史上看，Istio 的 API 设计遵循的路径与其他基础性平台的 API 相似。Istio 遵循下列设计原则：

1. Istio API 应该寻求：
    - 正确地表示他们映射到的基础资源
    - 不应该隐藏任何基础资源的有用功能
1. Istio API 也应该是 [可组合的](https://en.wikipedia.org/wiki/Composability)，因此终端用户能以适合其自身需求的方式组合基础 API。
1. Istio API 也应该是灵活的：在一个组织内部，应该有可能对基础资源有不同的表现形式，并且对每个团队都有意义。

在接下来的几个版本中，我们将分享我们的进展，我们将加强 Istio API 与 Istio 用户角色之间的一致性。

## 可组合性和抽象{#composability-and-abstractions}

Istio 和 Kubernetes 经常一起使用，但 Istio 更像是 Kubernetes 的附加组件 – Kubernetes 更接近于一个平台。Istio 旨在提供基础架构，并在强大的服务网格中展现您所需的功能。例如，有一些使用 Kubernetes 作为基础的 platform-as-a-service 产品，并基于 Kubernetes 的可组合性向应用开发人员提供 API 的子集。

Kubernetes 可组合性的一个具体示例是部署应用时有一系列的对象需要配置。根据我们的统计，至少有 10 个对象需要被配置：`Namespace`、`Service`、`Ingress`、`Deployment`、`HorizontalPodAutoscaler`、`Secret`、`ConfigMap`、`RBAC`、`PodDisruptionBudget` 和 `NetworkPolicy`。

听起来很复杂，但不是每个人都要和这些概念打交道。不同的团队有不同的职责，比如集群、网络、或者安全管理团队，并且许多配置提供合理的默认值。云原生平台和部署工具的一个巨大的优势是可以利用少量的信息来为你配置这些对象以隐藏这种复杂性。

可以在 [Google Cloud HTTP(S) Load Balancer](https://cloud.google.com/load-balancing/docs/https/) (GCLB) 找到网络空间可组合性的另一个例子。要正确使用 GCLB 的一个实例，需要创建和配置 6 个不同的基础对象。这样的设计是我们操作分布式系统 20 年经验的一个结果，并且[为什么每一个对象和其他对象相互独立是有原因的](https://www.youtube.com/watch?v=J5HJ1y6PeyE)。但你通过 Google Cloud 控制台创建一个实例的步骤是被简化过的。我们提供越多的通用的面向终端用户/以角色为中心的配置，以后你们配置的通用设置越少。最终，基础 API 的目标是在不牺牲功能的情况下提供最大的灵活性。

[Knative](http://knative.dev) 是一个创建、运行并且操作无服务器工作负载的平台，它提供了一个以角色为中心的现实世界绝佳的示例，更高层次的 API。[Knative Serving](https://knative.dev/docs/serving/)，Knative 的一个组件，基于 Kubernetes 和 Istio 服务于无服务器应用和功能，为应用开发人员管理服务的路由和修订提供了一个稳定的工作流。由于采用这种稳定的方式，Knative Serving 将 Istio 的 [`VirtualService`](/zh/docs/reference/config/networking/virtual-service/) 和 [`DestinationRule`](/zh/docs/reference/config/networking/destination-rule/) 资源，抽象成一个简化的支持修订和流量路由的 [路由](https://github.com/knative/docs/blob/master/docs/serving/spec/knative-api-specification-1.0.md#route) 对象，将与应用开发人员最紧密相关的 Istio 网络 API 的一个子集暴露出来。

随着 Istio 的成熟，我们还看到生产用户在 Istio 的基础 API 之上开发了针对特定工作负载和组织的抽象层。

AutoTrader UK 提供了一个基于 Istio 定制平台的我们最喜欢的例子。在 [来自 Google 的 Kubernetes Podcast 的一个采访](https://kubernetespodcast.com/episode/052-autotrader/) 中，Russel Warman 和 Karl Stoney 描述了他们基于 Kubernetes 的交付平台，和 [用 Prometheus 和 Grafana 搭建的成本 Dashboard](https://karlstoney.com/2018/07/07/managing-your-costs-on-kubernetes/)。他们毫不费力地添加了配置项使网络达到他们的开发人员希望配置成的样子，并且现在它管理着的 Istio 的对象让这一切成为可能。在企业和云原生公司中构建了无数其他的平台：一些旨在替换公司特定的自定义脚本的网络，而另一些旨在成为通用的公共工具。随着越来越多的公司开始公开谈论他们的工具，我们将把他们的故事带到此博客。

## 接下来会发生什么{#what’s-coming-next}

我们正在为即将发布的版本进行一些改进，其中包括：

- 通过 Istio operator 安装配置文件用来设置 ingress 和 egress 标准模式
- 自动推断容器端口和遥测协议
- 默认情况下支持路由所有流量，以逐步限制路由
- 添加单个全局标志以启用双向 TLS 并加密所有 Pod 间通信

噢，如果由于某种原因，你通过安装的 CRD 列表来判断工具箱，在 Istio 1.2 中我们将数字 54 减少到 23。为什么？事实证明，如果您有很多功能，则需要一种方法来配置所有功能。通过对安装程序的改进，您现在可以使用与适配器配合使用的[配置](/zh/docs/setup/additional-setup/config-profiles/)安装 Istio。

在所有的服务网格中，作为扩展，Istio 寻求将复杂的基础性操作自动化，比如网络和安全。这意味着总有些 API 是复杂的，但是 Istio 始终致力于解决操作者的需求，同时继续演变 API 以提供强大的构建块并通过以角色为中心的抽象来优先满足灵活性。

我们迫不及待地希望你加入我们的[社区](/zh/about/community/join/)，看看你会使用 Istio 构建出什么美妙的产品！

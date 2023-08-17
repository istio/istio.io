---
title: "Ambient Mesh 简介"
description: "Istio 无 Sidecar 的全新数据平面模式。"
publishdate: 2022-09-07T07:00:00-06:00
attribution: "John Howard (Google), Ethan J. Jackson (Google), Yuval Kohavi (Solo.io), Idit Levine (Solo.io), Justin Pettit (Google), Lin Sun (Solo.io)"
keywords: [ambient]
---

今天，我们很高兴介绍什么是 Ambient Mesh。这是一个全新的 Istio 数据平面模式，旨在简化操作，拓宽应用兼容性，降低基础设施成本。
Ambient Mesh 让用户无需使用 Sidecar 代理，就能将网格数据平面集成到其基础设施中，同时还能保持 Istio 的零信任安全、遥测和流量治理等核心特性。
我们与 Istio 社区分享了 Ambient Mesh 预览版，接下来的几个月内会努力将其提升至生产就绪状态。

## Istio 和 Sidecar {#istio-and-sidecars}

Istio 从诞生之初就定义了基本的架构：采用与应用容器并行的方式，部署使用 Sidecar 这种可编程的代理机制。
Sidecar 使得操作者尽享 Istio 带来的优势，应用程序无需接受大幅改造，也没有额外的关联成本。

{{< image width="100%"
    link="traditional-istio.png"
    caption="Istio 在工作负载的 Pod 内以 Sidecar 部署 Envoy 代理的传统模型"
    >}}

尽管 Sidecar 相比大幅改造应用具备相当大的优势，但 Sidecar 模式并未完美隔离应用和 Istio 数据平面。这就造成了一些问题：

* **侵入性** - Sidecar 必须通过修改 Kubernetes Pod 规约并在 Pod 内重定向流量才能“注入”到应用中。
  因此，安装或升级 Sidecar 都需要重启应用 Pod，这可能会破坏当前工作负载。
* **资源利用不足** - 由于 Sidecar 代理专用于其关联的工作负载，因此必须为每个 Pod 准备足够的 CPU 和内存资源以应付最糟糕的情形。
  这会使得资源被大量预留，从而导致整个集群的资源利用不足。
* **流量熔断** - 流量捕获和 HTTP 处理通常由 Istio 的 Sidecar 完成，计算成本较高，可能会因 HTTP 实现不合规而破坏一些应用。

Sidecar 的存在有其重要意义，后续也会为其添加更多特性，但我们认为需要有一种侵入更少、使用更简单的选项来更好地适配众多服务网格用户。

## 分层切片{#slicing-the-layers}

以往 Istio 采用单个架构组件 Sidecar 从基本加密到高级 L7 策略实现所有数据平面功能。
在实践中，这使得 Sidecar 成为一个 0 和 1 的命题（要么全有，要么全无）。
即使工作负载对传输安全性要求不高，管理员仍然需要付出部署和维护 Sidecar 的运营成本。
Sidecar 对每个工作负载具有固定的运营成本，无法扩展以应对各种复杂的应用场景。

Ambient Mesh 采用了一种不同的方式。
它将 Istio 的功能拆分成两个不同的层。
最底下是安全覆盖层，用于处理流量路由和零信任安全。
在此之上，用户可以在需要时启用 L7 处理机制赋予访问 Istio 完整特性的权限。
L7 处理模式要比安全覆盖层更重，仍然用作基础设施的一个环境组件，不需要对应用 Pod 进行修改。

{{< image width="100%"
    link="ambient-layers.png"
    caption="Ambient Mesh 的层"
    >}}

这种分层的方式允许用户以递进的方式采用 Istio，从没有网格平滑过渡到安全覆盖层，再根据需要按命名空间逐个过渡到完整的 L7 处理模式。
此外，在不同环境模式下运行的工作负载或与 Sidecar 一起运行的工作负载可以无缝互操作，允许用户根据特定需求随着时间的推移变化而混用和匹配各项能力。

## 构建 Ambient Mesh {#building-an-ambient-mesh}

Ambient Mesh 使用一个共享的代理，运行在 Kubernetes 集群的每个节点上。这个代理是零信任隧道（或 **_ztunnel_**），
它的主要职责是安全地连接网格内的各项元件并对其执行身份验证。
节点上的网络堆栈通过本地 ztunnel 代理重定向参与工作负载的所有流量。
这将 Istio 数据平面的关注点与应用的关注点完全分开，最终允许操作者在不干扰应用的情况下启用、禁用、扩缩和升级数据平面。
ztunnel 对工作负载流量不执行 L7 处理，这使其比 Sidecar 更精简。
这种复杂性和相关资源成本的大幅降低使其可以作为共享基础设施进行交付。

Ztunnel 实现服务网格的核心功能：零信任。
当为命名空间启用环境时会创建安全覆盖层。
它为工作负载提供 mTLS、遥测、身份验证和 L4 鉴权，而无需终止或解析 HTTP。

{{< image width="100%"
    link="ambient-secure-overlay.png"
    caption="Ambient Mesh 为每个节点使用共享的 ztunnel 来提供零信任安全覆盖层"
    >}}

启用 Ambient Mesh 并创建安全覆盖层后，可以配置一个命名空间利用 L7 特性。
这允许命名空间实现全套的 Istio 能力，包括[虚拟服务 API](/zh/docs/reference/config/networking/virtual-service/)、[L7 遥测](/zh/docs/reference/config/telemetry/) 和 [L7 鉴权策略](/zh/docs/reference/config/security/authorization-policy/)。
在这种模式下运行的命名空间使用一个或多个基于 Envoy 的 **_waypoint proxy_** 来处理该命名空间中工作负载的 L7。
Istio 的控制平面将集群中的 ztunnel 配置为通过 waypoint proxy 传递所有需要 L7 处理的流量。
值得一提的是，从 Kubernetes 的角度来看，waypoint proxy 就像常规的 Pod，可以像任何其他 Kubernetes Deployment 一样自动扩缩。
我们预计这将为用户节省大量资源，因为 waypoint proxy 可以自动扩缩以适应其所服务的命名空间的实时流量需求，而不是操作者预期的最大最糟情况下的负载。

{{< image width="100%"
    link="ambient-waypoint.png"
    caption="当需要其他特性时，Ambient Mesh 会部署 waypoint proxy，允许 ztunnel 通过这些代理执行策略"
    >}}

Ambient Mesh 使用基于 mTLS 的 HTTP CONNECT 来实现其安全隧道并在路径中插入 waypoint proxy，这种模式我们称之为 HBONE（基于 HTTP 的覆盖网络环境）。
HBONE 提供了比 TLS 本身更干净的流量封装，同时实现了与常见负载均衡器基础设施的互操作性。
默认情况下使用 FIPS 构建来满足合规性需求。
有关 HBONE、其基于标准的方法以及 UDP 和其他非 TCP 协议的计划的更多详情将在以后的博客中提供。

在单个网格中混用 Sidecar 和 Ambient 不会对系统的能力或安全属性造成任何限制。
无论选择何种部署模型，Istio 控制平面都能确保策略被正确实施。
Ambient 只是引入了一种更符合场景特性和更大灵活性的选项。

## 为什么本地节点上没有 L7 处理？{#why-no-l7-processing-on-the-local-node}

Ambient Mesh 在节点上使用一个共享的 ztunnel 代理来处理网格的零信任机制，而 L7 处理出现在单独调度 Pod 中的 waypoint proxy 中。
为什么要采用这种间接的方式，而不是在节点上使用共享的完整 L7 代理？有如下几个原因：

* Envoy 本质上不是多租户的。 因此，在一个共享实例中混用多个不受约束租户的 L7 流量的复杂处理规则存在安全问题。
  通过严格限制 L4 处理，能够显著减少漏洞影响范围。
* 与 waypoint proxy 所需的 L7 处理相比，ztunnel 提供的 mTLS 和 L4 特性所需的 CPU 和内存占用量更少。
  通过将 waypoint proxy 作为共享命名空间资源运行，可以根据该命名空间的需求进行独立的扩缩，且其成本不会不公平地分布到不相关的租户。
* 通过缩小 ztunnel 的范围，我们允许将其替代为其他可以满足明确定义的互操作性合约的安全隧道实现机制。

## 但那些额外的跃点又是怎么回事？{#but-what-about-those-extra-hops}

使用 Ambient Mesh，不一定保证 waypoint 与其服务的工作负载位于同一节点上。
虽然乍一看这似乎是一个性能问题，但我们相信延迟问题最终将与 Istio 当前的 Sidecar 实现保持一致。
我们将在专门的性能博客文章中讨论这部分内容，先在这里总结两点：

* Istio 的大部分网络延迟实际上并非来自网络[（现代云服务商拥有极快的网络）](https://www.clockwork.io/there-is-no-upside-to-vm-colocation/)。
  相反，罪魁祸首是 Istio 需要密集的 L7 处理来实现其复杂的特性集。
  Sidecar 为每个连接实现两个 L7 处理步骤（每个 Sidecar 一个），与之不同的是 Ambient Mesh 将这两个步骤合并为一个。
  在大多数情况下，我们希望通过降低处理成本来补偿额外的网络跃点。
* 用户通常首先部署网格以启用零信任安全态势，然后根据需要有选择地启用 L7 能力。
  Ambient Mesh 允许这些用户在不需要时完全绕过 L7 处理的成本。

## 资源开销{#resource-overhead}

总体而言，我们希望 Ambient Mesh 对大多数用户而言具有更少且更可预测的资源需求。
ztunnel 的有限职责允许将其部署为节点上的共享资源。
这将大幅减少大多数用户需要为每个工作负载预留的资源。
此外，由于 waypoint proxy 是普通的 Kubernetes Pod，所以可以根据所服务工作负载的实时流量需求进行动态部署和扩缩。

另一方面，Sidecar 需要为每个工作负载的最糟情况预留内存和 CPU。
这类计算很复杂，因此在实践中管理员更倾向于过度配置。
这就导致某些节点由于预留的资源过高而出现资源利用不足，而其他工作负载又因为没有资源而调度失败。
Ambient Mesh 针对每个节点的固定开销较低，且能够动态扩缩，waypoint proxy 合计所需的资源预留量更小，这样就能更高效地使用一个集群。

## 安全性怎样？{#what-about-security}

全新的架构自然会带来有关安全性的问题。
[Ambient 安全特性](/zh/blog/2022/ambient-security/)进行了深入探讨，我们在这里做一些总结。

因为 Sidecar 与其所服务的工作负载并置，所以一个出现漏洞就会危及另一个。
在 Ambient Mesh 模型中，即使一个应用受到攻击，ztunnel 和 waypoint proxy 仍能对受感染应用的流量执行严格的安全策略。
此外，Envoy 是世界上最大的网络运营商所使用的经实战考验的成熟软件，与其运行的应用相比 Envoy 遭受攻击的可能性较低。

虽然 ztunnel 是一种共享资源，但它只能访问当前在其运行节点上工作负载的密钥。
因此，它的受影响半径并不比任何其他依赖每个节点密钥进行加密的加密 CNI 差。
此外，ztunnel 的 L4 被攻击的影响范围有限，再考虑到上述 Envoy 的安全属性，我们认为这种风险有限，是可以接受的。

最后，虽然 waypoint proxy 是一种共享资源，但它们仅限于为一个服务账号服务。
这使得它们不会比如今的 Sidecar 更差。
如果一个 waypoint proxy 遭到破坏，则与该 waypoint 关联的凭据将丢失，但不会影响其他任何内容。

## 这是否是 Sidecar 的末路？{#is-this-the-end-of-the-road-for-the-sidecar}

绝对不是。
我们相信 Ambient Mesh 将是未来许多网格用户的最佳选择，但对于那些需要专用数据平面资源（例如合规性或性能调优）的用户来说，Sidecar 仍然是一个不错的选择。
Istio 将继续支持 Sidecar，重要的是将允许 Sidecar 与 Ambient Mesh 无缝互操作。
事实上，我们如今发布的 Ambient Mesh 代码已经支持与基于 Sidecar 的 Istio 互操作。

## 了解更多{#learn-more}

观看一段短视频，看看 Christian 如何运行 Istio Ambient Mesh 各个组件，视频中还演示了一些能力：

<iframe width="560" height="315" src="https://www.youtube.com/embed/nupRBh9Iypo" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

### 欢迎参与{#get-involved}

我们如今发布的是 Istio Ambient Mesh 的早期版本，它仍在积极开发中。
我们很高兴与更广泛的社区分享，期待有更多开发者参与其中，这一特性将在 2023 年达到生产就绪状态。

我们希望您的反馈有助于塑造解决方案。
支持 Ambient Mesh 的 Istio 构建位于 [Istio Experimental repo]({{< github_raw >}}/tree/experimental-ambient)，
请参阅[下载并试用](/zh/blog/2022/get-started-ambient/)。
[README]({{< github_raw >}}/blob/experimental-ambient/README.md) 列出了缺失特性和工作事项。
请多多试用并[让我们知道您的想法！](https://slack.istio.io/)

**感谢为 Ambient Mesh 的发布做出卓越贡献的团队！**
* _Google：Craig Box, John Howard, Ethan J. Jackson, Abhi Joglekar, Steven Landow, Oliver Liu, Justin Pettit, Doug Reid, Louis Ryan, Kuat Yessenov, Francis Zhou_
* _Solo.io：Aaron Birkland, Kevin Dorosh, Greg Hanson, Daniel Hawton, Denis Jannot, Yuval Kohavi, Idit Levine, Yossi Mesika, Neeraj Poddar, Nina Polshakova, Christian Posta, Lin Sun, Eitan Yarmush_

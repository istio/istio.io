---
title: 介绍istio
description: Istio 0.1 宣布
subtitle: 用于微服务的强大服务网格
publishdate: 2017-05-24
attribution: THE ISTIO TEAM
weight: 100
aliases:
    - /zh/blog/istio-service-mesh-for-microservices.html
    - /zh/blog/0.1-announcement.html   
---

google,IBM和Lyft自豪的宣布了[Istio](/)的第一个版本的发布：一个能提供连接，保护，管理和监视微服务的统一方式的开源项目。我们目前的发布是以[Kubernetes](https://kubernetes.io/)作为目标环境。我们还计划在最近一个月增加支持其他环境，比如虚拟机和Cloud Foundry。Istio为微服务增加了流量管理，并为安全，监控，路由，连接管理和策略等增值功能奠定了基础。它是由来自Lyft的经过实战考验的[Envoy](https://envoyproxy.github.io/envoy/)代理所构建，并提供对流量的可见性和控制，而*无需对应用程序代码进行任何更改*。Istio还为CIO提供了强大的工具，可以在企业使用过程中达到实施安全性，策略和合规性要求。

## 背景

编写基于微服务的可靠，松散耦合的生产级应用程序可能具有挑战性。 随着单体应用程序被分解为微服务，软件团队不得不担心在分布式系统中集成服务所固有的挑战：它们必须考虑到服务发现，负载平衡，容错，端到端监控，功能实验的动态路由， 也许最重要的是合规性和安全性。

libraries,scripts和Stack Overflow这些组织尝试去解决这些挑战，但是由于不一致导致解决方案在语言和运行时间之间变化很大，具有较差的可观察性特征，并且通常最终会危及安全性。

其中一种解决方案是在例如[gRPC](https://grpc.io)之类的公共RPC库上标准化实现，但是对于每个公司有着自己的技术栈，实际上不可能因此改变应用程序的结构，就算能改变但是代价可能是昂贵的。 运营商需要一个灵活的工具包来保证他们的微服务安全，合规，可跟踪和高度可用，开发人员需要能够在生产中试验不同的功能，或部署canary版本，而不会影响整个系统。

## 解决方案：服务网格

想象一下，如果我们能够在服务和网络之间透明地注入一层基础设施，为运营商提供所需的控制，同时让开发人员不必将分布式系统问题的解决方案耦合到他们的代码中。这种统一的基础设施层与服务部署相结合通常被称为**_服务网格_**。正如微服务有助于将功能团队彼此分离一样，服务网络有助于将操作员与应用程序功能开发和发布过程分离。通过将代理系统地注入到它们之间的网络路径中，Istio将不同的微服务转变为集成的服务网格。

基于我们为内部和企业客户构建和运营大规模微服务的共同经验，谷歌，IBM和Lyft联手创建了Istio，希望为微服务开发和维护提供可靠的基础。 Google和IBM在他们自己的应用程序中与这些大型微服务以及敏感/受监管环境中的企业客户拥有丰富的经验，而Lyft开发了Envoy以解决其内部可操作性挑战。 [Lyft开源Envoy](https://eng.lyft.com/announcing-envoy-c-l7-proxy-and-communication-bus-92520b6c8191)，在生产中成功使用它超过一年，管理超过100个服务，跨越10,000个虚拟机，处理2M请求/秒。

## Istio的好处

全舰队能见度：发生故障，运营商需要工具来保证群集的健康状况以及其微服务的监控图表。 Istio生成有关使用[Prometheus](https://prometheus.io/) & [Grafana](https://github.com/grafana/grafana)呈现的应用程序和网络行为的详细监视数据，并且可以轻松扩展以将度量和日志发送到任何集合，聚合和查询系统。 通过[Zipkin](https://github.com/openzipkin/zipkin) 跟踪，Istio可以分析性能热点和分布式故障模式的诊断。

{{< image width="100%" ratio="55.42%"
    link="/blog/2017/0.1-announcement/istio_grafana_dashboard-new.png"
    caption="Grafana Dashboard 的 Response 大小"
    >}}

{{< image width="100%" ratio="29.91%"
    link="/blog/2017/0.1-announcement/istio_zipkin_dashboard.png"
    caption="Zipkin Dashboard"
    >}}

**弹性和效率**：在开发微服务时，运营商需要假设网络不可靠。运营商可以使用重试，负载平衡，流量控制（HTTP / 2）和熔断来补偿由于网络不可靠而导致的一些常见故障模式。 Istio提供了统一的方法来配置这些功能，使操作高弹性服务网格变得更加容易。

**开发人员的工作效率**：Istio通过让开发者专注于以首选语言构建服务功能，显着提高了开发人员的工作效率，而Istio则以统一的方式处理弹性和网络挑战。开发人员不必将分布式系统问题的解决方案耦合到他们的代码中。通过提供支持A/B测试，金丝雀发布和故障注入的通用功能，Istio进一步提高了生产力。

**政策驱动行动**：Istio使具有不同关注领域的团队能够独立运营。它将集群运营商与功能开发周期分离，允许在不更改代码的情况下推出安全性，监控，扩展和服务拓扑的改进。运营商可以路由精确的生产流量子集，以限定新的服务版本。它们可以将错误或延迟注入流量以测试服务网格的弹性，并设置速率限制以防止服务过载。 Istio还可用于强制执行合规性规则，在服务之间定义ACL以仅允许授权服务相互通信。

**默认安全**：分布式计算的一个常见谬误是网络安全。 Istio使运营商能够使用相互TLS连接对服务之间的所有通信进行身份验证和保护，而不会给开发人员或运营商带来繁琐的证书管理任务。我们的安全框架与新兴的[SPIFFE](https://spiffe.github.io/)规范保持一致，并基于在Google内部进行过广泛测试的类似系统。

**增量采用**：我们将Istio设计为对网格中运行的服务完全透明，允许团队随着时间的推移逐步采用Istio的功能。采用者可以从启用全舰队能见度开始，一旦他们在环境中对Istio感到满意，他们就可以根据需要开启其他功能。

## 加入我们的旅程

Istio是一个完全开放的开发项目。 今天我们发布了0.1版，它在Kubernetes集群中运行，我们计划每3个月发布一次主要的新版本，包括对其他环境的支持。 我们的目标是使开发人员和运营商能够灵活地部署和运营微服务，完全了解底层网络，并在所有环境中实现统一的控制和安全性。 我们期待根据我们的[路线图](/about/feature-stages/)与Istio社区及其合作伙伴共同实现这些目标。

访问[此处](https://github.com/istio/istio/releases)获取最新发布的版本。

查看来自GlueCon 2017的[演示文稿](/talks/istio_talk_gluecon_2017.pdf)，其中Istio已经亮相。

## 社区

我们很高兴看到社区中许多公司早期致力于支持该项目：[Red Hat](https://blog.openshift.com/red-hat-istio-launch/) 与Red Hat OpenShift和OpenShift应用程序运行时，Pivotal与[Pivotal Cloud Foundry](https://content.pivotal.io/blog/pivotal-and-istio-advancing-the-ecosystem-for-microservices-in-the-enterprise)，WeaveWorks与 [Weave Cloud](https://www.weave.works/blog/istio-weave-cloud/)和Weave Net 2.0，[Tigera](https://www.projectcalico.org/welcoming-istio-to-the-kubernetes-networking-community)与项目Calico网络 使用Ambassador项目的Policy Engine和[Datawire](https://www.datawire.io/istio-and-datawire-ecosystem/) 。 我们希望看到更多的公司加入我们的行列。

要参与其中，请通过以下任意渠道与我们联系：

* [istio.io](istio.io)用于文档和示例。

* 有关一般讨论的邮件列表为[`istio-users@googlegroups.com`](https://groups.google.com/forum/#!forum/istio-users)或[`istio-announce@googlegroups.com`](https://groups.google.com/forum/#!forum/istio-announce)，以获取有关项目的重要公告。

* [Stack Overflow](https://stackoverflow.com/questions/tagged/istio)为策划的问题和答案

* [GitHub](https://github.com/istio/istio/issues) 提交问题

* Twitter上的[@IstioMesh](https://twitter.com/IstioMesh)

* 来自Istio的所有人，欢迎加入！

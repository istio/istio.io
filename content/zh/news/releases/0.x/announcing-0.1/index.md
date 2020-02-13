---
title: 初次了解 Istio
linktitle: 0.1
description: Istio 0.1 公告。
publishdate: 2017-05-24
subtitle: 一个为微服务而生的健壮的服务网格
aliases:
    - /zh/blog/istio-service-mesh-for-microservices.html
    - /zh/blog/0.1-announcement.html
    - /zh/about/notes/older/0.1
    - /zh/blog/2017/0.1-announcement
    - /zh/docs/welcome/notes/0.1.html
    - /zh/about/notes/0.1/index.html
    - /zh/news/2017/announcing-0.1
    - /zh/news/announcing-0.1
---

Google、 IBM 和 Lyft 骄傲的宣布了 [Istio](/zh) 的首个公开版本。Istio 是一个以统一方式对微服务实施连接、管理、监控以及安全增强的开源项目。当前版本专注于支持 [Kubernetes](https://kubernetes.io/) 环境，我们计划在接下来的几个月添加诸如虚拟机和 Cloud Foundry 等环境的支持。
Istio 为微服务添加了流量管理能力，同时为比如安全、监控、路由、连接管理和策略等附加能力打下了基础。此软件构建于来自 Lyft 的经过实战检验的 [Envoy](https://envoyproxy.github.io/envoy/) 代理之上，能在 *无需改动任何应用代码* 的情况下赋予对应用流量的可见性和控制能力。Istio 为 CIO 们提供了一个在企业内加强安全、策略和合规性的强有力的工具。

## 背景{#background}

基于微服务模式编写可靠的、松耦合的、产品级的应用是有挑战的。随着巨型单体应用被分解为微服务，软件团队不得不面对将微服务集成进分布式系统的挑战：服务发现、负载均衡、故障容忍、端到端监测、动态路由，还有最重要的合规和安全。

层出不穷的方案尝试解决这些挑战，互不一致的库、脚本和堆栈溢出代码段导致这些解决方案跨越多种语言和运行时，严重影响了可观测性，最终危及到安全。

有一个解决方案是使用通用 RPC 库比如 [gRPC](https://grpc.io)，但是这在大规模适配时花销不菲，且可能在某些事实上无法变更的应用上留下棕色地带。运维人员需要一个灵活的工具来使他们的微服务变得安全、合规、可追踪和高可用，开发人员也需要这种能力来在产品环境实验不同的功能或者部署金丝雀版本而不影响系统的完整性。

## 解决方案：服务网格{#solution-service-mesh}

想象一下如果我们可以在服务和网络之间透明的注入一层基础设施来给予运维人员所需要的控制能力的同时又能让开发人员免除需要将解决分布式系统问题的代码糅合到业务代码的烦恼。这种一致的基础设施层与服务开发的搭配通常被称之为 **_服务网格_**。正如微服务帮助不同的功能团队之间互相解耦，服务网格可以帮助解除功能开发和发布流程之间的耦合。Istio 通过在不同的服务网络间注入代理来将不同的微服务集成进同一个服务网格。

Google、IBM 和 Lyft 为了共同的愿景，基于为内部和企业客户构建和管理大规模微服务的经验合力创造了 Istio，以此来为微服务的开发和维护提供一个可靠的基础。Google 和 IBM 在他们自身的应用以及他们的企业客户的敏感的／受管制的环境中实施大规模微服务时积累了丰富的经验，同时 Lyft 开发了 Envoy 以解决他们内部面对的挑战。在成功的将其应用于生产环境，管理过能每秒处理两百万个请求的分布于上万个虚拟机 超过100个微服务一年后 [Lyft 开源 Envoy](https://eng.lyft.com/announcing-envoy-c-l7-proxy-and-communication-bus-92520b6c8191) 。

## Istio 的好处{#benefits-of-Istio}

**集群范围的可见性**：故障时有发生，运维人员需要工具来监控集群健康和微服务状态。Istio 生成有关应用和网络行为的详细监测数据，可使用 [Prometheus](https://prometheus.io/) 和 [Grafana](https://github.com/grafana/grafana) 渲染，也可以发送指标和日志到任何收集、聚合和查询的系统以轻松的扩展其功能。Istio 使用 [Zipkin](https://github.com/openzipkin/zipkin) 提供分析性能瓶颈和诊断分布式故障的功能。

{{< image link="./istio_grafana_dashboard-new.png" caption="Grafana Dashboard with Response Size" >}}

{{< image link="./istio_zipkin_dashboard.png" caption="Zipkin Dashboard" >}}

**适应能力和效率**：当开发微服务时，运维人员需要假设网络是不可靠的。运维人员可以使用重试、负载均衡、流程控制（HTTP/2）和熔断等措施来缓解不可靠网络中这些常见的故障。Istio 提供了一致的方式来配置这些功能，使其易于维护一个高适应性的服务网格。

**开发者生产力**：Istio 使开发者专注于使用他们喜欢的编程语言构建服务功能，这有效的提升了开发者的生产力，同时 Istio 使用统一的方式处理适应性和网络认证。开发者免于将解决分布式系统问题的代码糅合到业务代码。Istio 提供支持 A/B 测试、金丝雀部署和故障注入的通用功能进一步的提高了生产力。

**策略驱动运维**：Istio 赋予肩负不同职责的团队以独立操作的能力。它将集群管理员从应用部署环节中分离，这可以增强应用的安全、监测、伸缩和服务拓扑等能力而 *不需要* 变更代码。运维人员可以精确的路由一部分生产流量用于检验一个新版本的服务。他们可以在流量中注入故障和延迟来测试服务网格的适应能力，同时可以设置请求限制来放置服务被过载。Istio 也可以被用于确保合规，在服务间定义 ACL 可以仅允许被授权的服务才能相互访问。

**默认安全**：一个常见的缪误是认为分布式计算的网络是安全的。Istio 使用双向 TLS 连接，使运维人员可以确保服务之间的通信是经过认证和安全的，而使开发者或运维人员无需负担繁重的认证管理任务。我们的安全框架符合 [SPIFFE](https://spiffe.io/) 规范，且基于在 Google 内部经过大范围测试的类似系统。

**渐进式适配**：我们有意使 Istio 对于运行于网格中的服务完全透明，这允许团队逐步适配 Istio 的功能。适配人员可以首先启用集群范围内的可见性，一旦他们适应了 Istio 的存在，他们可以按需开启其他功能。

## 加入我们{#join-us-in-this-journey}

Istio 是一个完全开放的开发项目。今天我们发布了能工作于 Kubernetes 集群的 0.1 版本，我们计划每三个月发布一个大版本，包括支持更多的环境。我们的目标是赋能开发者和运维人员，使他们在所有环境中都能敏捷的发布和维护微服务，拥有底层网络的完全的可见性，且获得一致的控制和安全能力。我们期待与 Istio 社区和我们的合作伙伴一起沿着 [路线图](/zh/about/feature-stages/) 朝着这些目标前进。

访问 [此处](https://github.com/istio/istio/releases) 获取最新发布的代码。

查看在 GlueCon 2017 公布 Istio 时的 [介绍](/talks/istio_talk_gluecon_2017.pdf)。

## 社区{#community}

我们很兴奋的看到来自社区中很多公司的早期支持：
[Red Hat](https://blog.openshift.com/red-hat-istio-launch/) 的 Red Hat OpenShift 和 OpenShift Application Runtimes，
Pivotal 的 [Pivotal Cloud Foundry](https://content.pivotal.io/blog/pivotal-and-istio-advancing-the-ecosystem-for-microservices-in-the-enterprise)，
WeaveWorks 的 [Weave Cloud](https://www.weave.works/blog/istio-weave-cloud/) 和 Weave Net 2.0，
[Tigera](https://www.projectcalico.org/welcoming-istio-to-the-kubernetes-networking-community) 的 Calico Network Policy Engine 项目，还有 [Datawire](https://www.datawire.io/istio-and-datawire-ecosystem/) 的 Ambassador 项目。我们期待看到更多的公司加入我们。

想要参与时可以通过以下任意渠道与我们联系：

- [istio.io](/zh) 提供文档和示例。

- [Istio discussion board](https://discuss.istio.io) 综合交流区。

- [Stack Overflow](https://stackoverflow.com/questions/tagged/istio) 用于问答

- [GitHub](https://github.com/istio/istio/issues) 用于提交 Issue

- Twitter [@IstioMesh](https://twitter.com/IstioMesh)

欢迎登船！

## 发布说明{#release-notes}

- 使用单个命令将 Istio 安装到 Kubernetes namespace 中。
- 将 Envoy proxy 半自动注入至 Kubernetes Pod 中。
- 使用 iptables 自动捕获 Kubernetes Pod 的流量。
- 针对 HTTP，gRPC 和 TCP 流量的集群内负载平衡。
- 支持超时，预算重试和熔断器。
- Istio 集成的 Kubernetes Ingress 支持（Istio 充当 Ingress Controller）。
- 细粒度的流量路由控件，包括 A/B 测试，金丝雀，红/黑部署。
- 灵活的内存速率限制。
- 使用 Prometheus 进行 HTTP 和 gRPC 的 L7 遥测和日志记录。
- Grafana 仪表板显示每个服务的 L7 指标。
- 使用 Envoy 及 Zipkin 实现请求跟踪。
- 使用双向 TLS 实现 service-to-service 的认证。
- 使用拒绝表达式实现简单 service-to-service 的认证。

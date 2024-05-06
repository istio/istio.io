---
title: "Bol.com 使用 Istio 扩展电子商务"
linkTitle: "Bol.com 使用 Istio 扩展电子商务"
quote: "Istio 的部署是轻而易举的。您安装它，它就会运行。"
author:
    name: "Roland Kool"
    image: "/img/authors/roland-kool.png"
companyName: "bol.com"
companyURL: "https://bol.com/"
logo: "/logos/bol-com.png"
skip_toc: true
skip_byline: true
skip_pagenav: true
doc_type: article
sidebar_force: sidebar_case_study
type: 案例探究
weight: 30
---

Bol.com 是荷兰最大的在线零售商，销售从书籍到电子产品再到园艺设备的所有商品。
该公司成立于 1999 年，现已发展壮大，为荷兰和比利时超过 1100 万名客户提供服务。
可想而知，他们的技术堆栈和 IT 基础设施多年来得到了大幅增长和发展。

他们商业经营背后的基础设施过去是由第三方托管的，但 bol.com 最终决定构建并自动化自己的基础设施。
在 2010 年末，bol.com 开始迁移到云端。随着越来越多的服务进入云，团队被授权构建和部署自己的基于云的服务和基础设施。

## 挑战 {#challenge}

当 bol.com 开始将业务迁移到云端时，他们面临着不可避免的成长阵痛。
他们开始将应用程序转移到 Kubernetes 集群中，并随着时间的推移添加越来越多的 Pod。
一开始集群地址空间似乎有足够的空间。不幸的是，需求的迅速扩展很快就成了一个问题。
他们最初为集群配置了一个服务 CIDR，其中有大约 1000 个地址的空间，但仅仅一年后，它的使用量就已经达到了 80%。

Roland Kool 是 bol.com 团队解决这个问题的系统工程师之一。
面对 Kubernetes 集群中的可用 IP 地址空间无法满足不断增长的业务需求问题，团队需要一种解决方案，
使溢出的 IP 地址能够进入其他集群。此外，这种新的多集群 Kubernetes 部署将带来新的网络挑战，
因为应用程序将需要一种新的方法来进行服务发现、负载均衡和安全通信。

## 解决方案：具有服务网格的多集群 {#solution-multiple-clusters-with-a-service-mesh}

解决方案似乎引入额外的集群，但它们遇到了安全需求和保护服务之间流量的网络策略的问题。

保护个人身份信息（PII）的需要加剧了这一挑战。由于 GDPR 等欧洲法规，
每一个涉及 PII 的服务都需要被识别，并严格控制访问。

由于网络策略是集群本地的，所以它们不能跨越集群边界进行工作。
所以每个集群的网络策略很快就变得混乱起来。他们需要一个解决方案，使他们能够在更高层应用安全性。

Istio 的[多集群部署模型](/zh/docs/ops/deployment/deployment-models/#multiple-clusters)最终成为完美的解决方案。
[授权策略](/zh/docs/reference/config/security/authorization-policy/)可用于安全地允许来自不同集群的工作负载相互通信。
借助 Istio，Kool 的团队能够从 OSI 第 3 层或第 4 层网络策略转向在第 7 层实施的 [authz 策略](/zh/docs/tasks/security/authorization/authz-http/)。
Istio 强大的身份支持、服务到服务的身份验证以及相互 TLS（mTLS）的安全性使这一举措成为可能。

这些变化使 bol.com 能够通过添加新的 Kubernetes 集群来扩展新增的业务需求，
同时保持服务发现、负载均衡所需的安全策略。

## 为什么是 Istio？ {#Why-Istio?}

当 bol.com 最初开始迁移到 Kubernetes 时，Istio 的版本仅为 0.2。
它似乎还没有准备好进行生产，所以他们在没有 Istio 的情况下继续前进。他们最初开始认真研究 Istio 是在 1.0 版左右，
但在部署和实施方面遇到了太多问题。并且由于没有紧急的用例，他们便搁置了这个想法。

然而，最终让 bol.com 重新采用 Istio 解决方案的不仅仅是扩展问题。
除了需要 Kubernetes 集群安全地互相通信外，他们还面临新的监管要求，这需要与各种第三方服务和 API 进行安全通信。
这些控制不能基于不断变化的防火墙规则和 IP 范围——它们需要基于应用程序的身份。

他们的解决方案利用了 [Istio 出口网关](/zh/docs/tasks/traffic-management/egress/egress-gateway/)。
这使他们能够应用 authz 控制，这些控制可以基于诸如客户端工作负载的身份或命名空间、目标主机名，
甚至 HTTP 请求的 URL 等属性来允许或拒绝流量。

Bol.com 需要一个支持多集群部署的服务网格，而 Istio 正好符合这个要求。
此外，Istio 还提供了满足特定需求所需的细粒度控制。

## 结果：启用 DevOps {#results-enabling-devOps}

“Istio 的部署是轻而易举的，”Roland Kool 解释道。“您安装它，它就会运行。”

安装 Istio 之后，他们开始着手实现对他们来说很重要的服务网格特性。
推出 Sidecar 需要各个团队的额外工作，以及负责实现 Istio 的团队的支持。

对于 Kool 和 bol.com 团队来说，最大的变化之一是围绕服务实现授权策略突然变得更加容易。
目前，Istio 在 bol.com 的使用率约为 95%，而且还在继续增长。
要让所有开发人员都满意可能很困难，但是 Istio 部署团队努力使其易于采用和集成。

开发人员提供了很好的反馈，并热情地接受了 Istio 的许多功能。
他们很高兴地看到，现在让应用程序在集群间相互通信是多么容易。由于 Istio，所有这些连接都易于设置和管理。

bol.com 基础设施不断发展，由于它提供的可观测性，Istio 是该路线图的关键部分。
通过[将 Istio 与 Prometheus 集成](/zh/docs/ops/integrations/prometheus/)，
他们能够收集所需的指标和诊断信息，以了解路线图需要将它们带到何处。
未来的计划现在包括整合负载均衡服务、新的测试方法、分布式跟踪以及在公司的更多基础设施中安装 Istio。

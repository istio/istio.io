---
title: "Istio 先锋英国 AutoTrader 仍然受益"
linkTitle: "Istio 先锋英国 AutoTrader 仍然受益"
quote: "Istio是一个服务网格，可提供所有微服务环境所需的跨领域功能"
author:
    name: "Karl Stoney"
    image: "/img/authors/karl-stoney.png"
companyName: "AutoTrader UK"
companyURL: "https://autotrader.co.uk/"
logo: "/logos/autotrader.svg"
skip_toc: true
skip_byline: true
skip_pagenav: true
doc_type: article
sidebar_force: sidebar_case_study
type: case-studies
---
[comment]: <> (TODO: Replace placeholders)

英国 Auto Trader 成立于 1977 年，是英国主要的汽车市场杂志。20 世纪末，当它转向在线业务时，它发展成为该国的第 16 大网站。

支持 AutoTrader 的 IT 领域非常广泛。如今，Auto Trader 管理着 40 至 50 个面向客户的应用程序，这些应用程序由大约 400 个微服务支持，每秒可处理 30,000 多个请求。他们面向公众的基础架构在 Google Kubernetes Engine（GKE）上运行，并利用 Istio 服务网格。作为主要的 Istio 成功案例，Auto Trader 在 2018 年向公有云服务的迁移已引起了广泛关注。值得了解其迁移背后的决策以及持续的利益。

## 挑战 {#challenge}

内部和供应商需求的变化促使 Auto Trader 迁移到 GKE 和 Istio。特别的一项要求是需要为所有微服务透明地部署相互TLS（mTLS）。事实证明，这种努力对于主要定制的基础设施而言是不朽的。

由于合作伙伴和供应商的要求，部署 mTLS 并不仅仅是必需的。Auto Trader 计划将其大部分基础架构移至公有云。强大的端到端 mTLS 对于保护他们的整个微服务生态系统至关重要。

## 解决方案：Istio 和 Google Kubernetes Engine {#solution-Istio-and-Google-Kubernetes-Engine}

Auto Trader IT 团队在将服务迁移到公有云方面已经拥有良好的记录。显然，这是越来越多的基础设施的最终目的地。面对实施 mTLS 的问题，IT 团队的一部分尝试使用 Istio 作为服务网格对现有应用程序进行容器化并将其部署在 GKE 上。

实验是成功的。在 GKE 上几天之内就完成了其他团队在私有云上花费数周时间的工作。此外，Istio 服务网格在整个微服务体系结构中提供了无缝的端到端 mTLS。

{{< quote caption="Karl Stoney，Auto Trader 基础设施交付领导" >}}
我们决定只试用 Istio 看看它会如何发展，最终我们交付了大约一周的时间–比过去四个月自己尝试将其交付的结果还要多。
{{< /quote >}}

## 为什么选择 Istio？{#why-Istio}

尽管所有微服务都易于向 mTLS 过渡非常有力，但 Istio 也得到了许多大型组织的支持。Auto Trader 已与 Google 合作，因此知道 Google 是 Istio 的强大支持者就使他们充满信心，它将得到支持并长期发展。

与 Istio 一起在GKE上进行的实验取得了早期成功，因此很快就被该业务所接受。他们试图实施几个月的功能突然在短短一周内就准备就绪。Istio 不仅能够提供 mTLS，还能够提供可靠的重试和备份策略以及异常检测。

## 结果：现象可观测性 {#results-phenomenal-observability}

Istio 使 Auto Trader 有信心将所有应用程序部署到公有云。随着可观察性的提高，他们现在有了一种新的方式来管理和考虑基础结构。他们突然对性能和安全性有了洞察力，与此同时 Istio 正在帮助他们发现一直存在的未被发现的漏洞。

### 平台交付团队的诞生 {#emergence-of-a-platform-delivery-team}

他们不仅能够快速部署，还可以将 Kubernetes 和 Istio 解决方案作为内部产品打包到其他开发和部署团队中。一个十人的团队现在管理着一个交付平台，该平台为 200 多个其他开发人员提供服务。

虽然 Kubernetes 的最初意图是实现更好的应用程序部署和资源管理，但是添加 Istio 带来了对应用程序性能的深刻见解的好处。可观测性是关键。Auto Trader 现在能够测量精确的资源利用和微服务交易。

虽然这不是完全透明的迁移，但是 Istio 和 Kubernetes 的好处鼓励了所有产品团队进行迁移。由于 Istio 无需管理的依赖项就更少，并且可以自动提供许多功能，因此项目团队几乎可以毫不费力地满足跨功能需求。团队能够在几分钟内在全球范围内部署 Web 应用程序，而新的基础架构则可以轻松地每天处理约 200 至 250 项部署。

### 激活 CI/CD {#enabling-CI-CD}

甚至一个全新的应用程序也可以在五分钟内完成部署。现有应用程序的快速部署已经改变了 Auto Trader 的发布方法。他们不再使用发布周期，而是使用 CI/CD 快速部署新更改。使用 Istio 进行的微调监控使部署团队可以快速而准确地查明新部署中的问题。各个团队可以查看自己的绩效仪表板。如果他们看到新的错误，可以通过 CI/CD 仪表板立即回滚更改。Istio 的恢复时间仅为数分钟。

Auto Trader 收购了一个大型的，完全定制的 IT 资产，并将其系统地转移到公共云上的微服务。他们对 Istio 的实施是迁移成功的关键部分，并为整个组织开放了更好的流程，更好的可观测性和更好的应用程序。

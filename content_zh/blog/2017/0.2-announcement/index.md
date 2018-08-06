---
title: 宣布 Istio 0.2
description: Istio 0.2 公告。
publishdate: 2017-10-10
subtitle: 改善网格并支持多种环境
attribution: The Istio Team
weight: 96
aliases:
    - /blog/istio-0.2-announcement.html
---

我在2017年5月24日发布了 Istio ，它是一个用于连接、管理、监控和保护微服务的开放平台。看着饱含浓厚兴趣的开发者、运营商、合作伙伴和不断发展的社区，我们感到十分的欣慰。我们 0.1 版本的重点是展示 Istio 在 Kubernetes 中的所有概念。

今天我们十分高兴地宣布推出 0.2 版本，它提高了稳定性和性能、允许在 Kubernetes 集群中广泛部署并自动注入 sidecar 、为 TCP 服务添加策略和身份验证、同时保证扩展网格收录那些部署在虚拟机中的服务。此外，Istio 可以利用 Consul/Nomad 或 Eureka 在 Kubernetes 外部运行。 除了核心功能，Istio 的扩展已经准备由第三方公司和开发人员编写。

## 0.2版本的亮点

### 可用性改进

* _支持多命名空间_:  Istio 现在可以跨多个名称空间在群集范围内工作，这也是来自 0.1 版本中社区最强烈的要求之一。
* _TCP 服务的策略与安全_: 除了 HTTP ，我们还为 TCP 服务增加了透明双向 TLS 认证和策略实施。这将让拥有像遥测，策略和安全等 Istio 功能的同时，保护更多 Kubernetes deployment 。
* _自动注入 sidecar_: 通过利用 Kubernetes 1.7 提供的 alpha  [初始化程序](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) ，当您的集群启用了该程序时，envoy sidecar 就可以自动注入到应用的 deployment 里。  这使得你可以使用  `kubectl` 命令部署微服务， 这与您通常在没有 Istio 的情况下部署微服务的命令完全相同。
* _扩展 Istio_ : 改进的 Mixer 设计，可以允许供应商编写 Mixer 适配器以实现对其自身系统的支持，例如应用管理或策略实施。该 [Mixer 适配器开发指南](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide) 可以轻松的帮你将 Istio 集成于你的解决方案。
* _使用您自己的 CA 证书_: 允许用户提供自己的密钥和证书给 Istio CA 和永久 CA 密钥/证书存储，允许在持久化存储中提供签名密钥/证书，以便于 CA 重启。
* _改进路由和指标_: 支持 WebSocket 、MongoDB 和 Redis 协议。 您可以将弹性功能（如熔断器）应用于第三方服务。除了 Mixer 的指标外，数以百计 Envoy 指标现在已经在 Prometheus 中可见，它们用于监控 Istio 网格中的流量吞吐。

### 跨环境支持

* _网格扩展_:  Istio 网格现在可以在 Kubernetes 之外跨服务 ——  就像那些运行在虚拟机中的服务一样，他们同时享受诸如自动双向 TLS认证、流量管理、遥测和跨网格策略实施带来的好处。

* _运行在 Kubernetes 外部_: 我们知道许多客户使用其他的服务注册中心和 orchestration 解决方案（如 [Consul/Nomad](/docs/setup/consul/quick-start/) 和 Eureka）， Istio Pilot 可以在 Kubernetes 外部单独运行，同时从这些系统中获取信息，并在虚拟机或容器中管理 Envoy fleet 。

## 加入到塑造 Istio 未来的队伍中

呈现在我们面前的是一幅不断延伸的[蓝图](/about/feature-stages/) ，它充满着强大的潜能。我们将在下个版本致力于 Istio 的稳定性，可靠性，第三方工具集成和多集群用例。

想要了解如何参与并为 Istio 的未来做出贡献，请查看我们在 GitHub 的[社区](https://github.com/istio/community)项目，它将会向您介绍我们的工作组，邮件列表，各种社区会议，常规流程和指南。

我们要感谢为我们测试新版本、提交错误报告、贡献代码、帮助其他成员以及通过参与无数次富有成效的讨论塑造 Istio 的出色社区，这让我们的项目自启动以来在GitHub上累积了3000颗星，并且在 Istio 邮件列表上有着数百名活跃的社区成员。

谢谢

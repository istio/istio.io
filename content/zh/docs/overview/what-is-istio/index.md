---
title: Istio 是什么？
description: 了解 Istio 能为您做什么。
weight: 10
keywords: [introduction]
owner: istio/wg-docs-maintainers-english
test: n/a
---

Istio is an open source service mesh that layers transparently onto existing distributed applications. Istio’s powerful features provide a uniform and more efficient way to secure, connect, and monitor services. Istio is the path to load balancing, service-to-service authentication, and monitoring – with few or no service code changes. It gives you:
Istio 是一种开源服务网格，可透明地分层到现有的分布式应用程序上。Istio 的强大功能提供了一种统一且更高效的方式来保护、连接和监控服务。Istio 是实现负载平衡、服务到服务身份验证和监控的途径 - 几乎无需更改服务代码。它为您提供：

* Secure service-to-service communication in a cluster with mutual TLS encryption, strong identity-based authentication and authorization
* Automatic load balancing for HTTP, gRPC, WebSocket, and TCP traffic
* Fine-grained control of traffic behavior with rich routing rules, retries, failovers, and fault injection
* A pluggable policy layer and configuration API supporting access controls, rate limits and quotas
* Automatic metrics, logs, and traces for all traffic within a cluster, including cluster ingress and egress
* 使用相互 TLS 加密、强大的基于身份的身份验证和授权在集群中保护服务到服务通信
* HTTP、gRPC、WebSocket 和 TCP 流量的自动负载平衡
* 使用丰富的路由规则、重试、故障转移和故障注入对流量行为进行细粒度控制
* 支持访问控制、速率限制和配额的可插入策略层和配置 API
* 集群内所有流量（包括集群入口和出口）的自动指标、日志和跟踪

Istio is designed for extensibility and can handle a diverse range of deployment needs. Istio’s {{< gloss >}}control plane{{< /gloss >}} runs on Kubernetes, and you can add applications deployed in that cluster to your mesh, [extend the mesh to other clusters](/docs/ops/deployment/deployment-models/), or even [connect VMs or other endpoints](/docs/ops/deployment/vm-architecture/) running outside of Kubernetes.
Istio 专为可扩展性而设计，可以处理各种部署需求。Istio 的 {{< gloss >}} 控制平面 {{< /gloss >}} 在 Kubernetes 上运行，您可以将部署在该集群中的应用程序添加到您的网格中，[将网格扩展到其他集群](/docs/ops/deployment/deployment-models/)，甚至[连接在 Kubernetes 之外运行的虚拟机或其他端点](/docs/ops/deployment/vm-architecture/)。

A large ecosystem of contributors, partners, integrations, and distributors extend and leverage Istio for a wide variety of scenarios. You can install Istio yourself, or a [large number of vendors](/about/ecosystem)) have products that integrate Istio and manage it for you.
庞大的贡献者、合作伙伴、集成商和分销商生态系统扩展了 Istio 并使其适用于各种场景。您可以自行安装 Istio，也可以使用 [大量供应商](/about/ecosystem)) 提供的产品来集成 Istio 并为您管理它。

## How it works
## 如何工作的 {#how-it-works}

Istio uses a proxy to intercept all your network traffic, allowing a broad set of application-aware features based on configuration you set.
Istio 使用代理来拦截您的所有网络流量，从而根据您设置的配置允许使用一系列应用程序感知功能。

The control plane takes your desired configuration, and its view of the services, and dynamically programs the proxy servers, updating them as the rules or the environment changes.
控制平面采用您所需的配置及其对服务的视图，并动态地编程代理服务器，并根据规则或环境的变化对其进行更新。

The data plane is the communication between services. Without a service mesh, the network doesn’t understand the traffic being sent over, and can’t make any decisions based on what type of traffic it is, or who it is from or to.
数据平面是服务之间的通信。如果没有服务网格，网络就无法理解正在发送的流量，也无法根据流量类型、流量来源或目的地做出任何决策。

Istio supports two data plane modes:
Istio 支持两种数据平面模式：

* **sidecar mode**, which deploys an Envoy proxy along with each pod that you start in your cluster, or running alongside services running on VMs.
* **ambient mode**, which uses a per-node Layer 4 proxy, and optionally a per-namespace Envoy proxy for Layer 7 features.
* **sidecar 模式**，它会与您在集群中启动的每个 pod 一起部署一个 Envoy 代理，或者与在虚拟机上运行的服务一起运行。
* **ambient 模式**，它使用每个节点的第 4 层代理，并且可选地使用每个命名空间的 Envoy 代理来实现第 7 层功能。

[Learn how to choose which mode is right for you](/docs/overview/dataplane-modes/).
[了解如何选择适合您的模式](/docs/overview/dataplane-modes/)。

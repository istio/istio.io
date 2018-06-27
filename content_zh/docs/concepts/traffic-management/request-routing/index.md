---
title: 请求路由
description: 在 Istio 服务网格中，如何在服务之间对请求进行路由。
weight: 20
keywords: [traffic-management,routing]
---

此节描述在 Istio 服务网格中，如何在服务之间对请求进行路由。

## 服务模型和服务版本

如 [Pilot](/docs/concepts/traffic-management/pilot/) 所述，特定网格中服务的规范表示由 Pilot 维护。服务的 Istio 模型和在底层平台（Kubernetes、Mesos 以及 Cloud Foundry 等）中的表达无关。特定平台的适配器负责从各自平台中获取元数据的各种字段，然后对服务模型进行填充。

Istio 引入了服务版本的概念，可以通过版本（`v1`、`v2`）或环境（`staging`、`prod`）对服务进行进一步的细分。这些版本不一定是不同的 API 版本：它们可能是部署在不同环境（prod、staging 或者 dev 等）中的同一服务的不同迭代。使用这种方式的常见场景包括 A/B 测试或金丝雀部署。Istio 的[流量路由规则](/docs/concepts/traffic-management/rules-configuration/)可以根据服务版本来对服务之间流量进行附加控制。

## 服务之间的通讯

{{< image width="60%" ratio="100.42%"
    link="/docs/concepts/traffic-management/request-routing/ServiceModel_Versions.svg"
    alt="服务版本的处理。"
    caption="服务版本"
    >}}

如上图所示，服务的客户端不知道服务不同版本间的差异。他们可以使用服务的主机名或者 IP 地址继续访问服务。Envoy sidecar/代理拦截并转发客户端和服务器之间的所有请求和响应。

运维人员使用 Pilot 指定路由规则，Envoy 根据这些规则动态地确定其服务版本的实际选择。该模型使应用程序代码能够将它从其依赖服务的演进中解耦出来，同时提供其他好处（参见 [Mixer](/docs/concepts/policies-and-telemetry/overview/)）。路由规则让 Envoy 能够根据诸如 header、与源/目的地相关联的标签和/或分配给每个版本的权重等标准来进行版本选择。

Istio 还为同一服务版本的多个实例提供流量负载均衡。可以在[服务发现和负载均衡](/docs/concepts/traffic-management/load-balancing/)中找到更多信息。

Istio 不提供 DNS。应用程序可以尝试使用底层平台（kube-dns，mesos-dns 等）中存在的 DNS 服务来解析 FQDN。

## Ingress 和 Egress

Istio 假定进入和离开服务网络的所有流量都会通过 Envoy 代理进行传输。通过将 Envoy 代理部署在服务之前，运维人员可以针对面向用户的服务进行 A/B 测试，部署金丝雀服务等。类似地，通过使用 Envoy 将流量路由到外部 Web 服务（例如，访问 Maps API 或视频服务 API）的方式，运维人员可以为这些服务添加超时控制、重试、断路器等功能，同时还能从服务连接中获取各种细节指标。

{{< image width="60%" ratio="28.88%"
    link="/docs/concepts/traffic-management/request-routing/ServiceModel_RequestFlow.svg"
    alt="通过 Envoy 的 Ingress 和 Egress。"
    caption="请求流"
    >}}

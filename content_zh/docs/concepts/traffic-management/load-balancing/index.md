---
title: 发现与负载均衡
description: 描述 Istio 如何在服务网格的服务实例之间实现流量的负载均衡。
weight: 25
keywords: [traffic-management,load-balancing]
---

本页描述 Istio 如何在服务网格的服务实例之间实现流量的负载均衡。

**服务注册**：Istio 假定存在服务注册表，以跟踪应用程序中服务的 pod/VM。它还假设服务的新实例自动注册到服务注册表，并且不健康的实例将被自动删除。诸如 Kubernetes、Mesos 等平台已经为基于容器的应用程序提供了这样的功能。为基于虚拟机的应用程序提供的解决方案就更多了。

**服务发现**：Pilot 使用来自服务注册的信息，并提供与平台无关的服务发现接口。网格中的 Envoy 实例执行服务发现，并相应地动态更新其负载均衡池。

{{<image width="80%" ratio="74.79%"
    link="/docs/concepts/traffic-management/LoadBalancing.svg"
    caption="发现与负载均衡">}}

如上图所示，网格中的服务使用其 DNS 名称访问彼此。服务的所有 HTTP 流量都会通过 Envoy 自动重新路由。Envoy 在负载均衡池中的实例之间分发流量。虽然 Envoy 支持多种[复杂的负载均衡算法](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/load_balancing)，但 Istio 目前仅允许三种负载平衡模式：轮循、随机和带权重的最少请求。

除了负载均衡外，Envoy 还会定期检查池中每个实例的运行状况。Envoy 遵循熔断器风格模式，根据健康检查 API 调用的失败率将实例分类为不健康或健康。换句话说，当给定实例的健康检查失败次数超过预定阈值时，它将从负载均衡池中弹出。类似地，当通过的健康检查数超过预定阈值时，该实例将被添加回负载均衡池。您可以在[处理故障](/docs/concepts/traffic-management/#handling-failures)中了解更多有关 Envoy 的故障处理功能。

服务可以通过使用 HTTP 503 响应健康检查来主动减轻负担。在这种情况下，服务实例将立即从调用者的负载均衡池中删除。
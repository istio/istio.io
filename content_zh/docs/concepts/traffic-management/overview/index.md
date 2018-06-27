---
title: 概览
description: 提供 Istio 中流量管理的概念性概述及其支持的功能。
weight: 1
keywords: [traffic-management]
---

本页概述了 Istio 中流量管理的工作原理，包括流量管理原则的优点。本文假设你已经阅读了 [Istio 是什么？](/docs/concepts/what-is-istio/overview/)并熟悉 Istio 的高级架构。有关单个流量管理功能的更多信息，您可以在本节其他指南中了解。

## Pilot 和 Envoy

Istio 流量管理的核心组件是 [Pilot](/docs/concepts/traffic-management/pilot/)，它管理和配置部署在特定 Istio 服务网格中的所有 Envoy 代理实例。它允许您指定在 Envoy 代理之间使用什么样的路由流量规则，并配置故障恢复功能，如超时、重试和熔断器。它还维护了网格中所有服务的规范模型，并使用这个模型通过发现服务让 Envoy 了解网格中的其他实例。

每个 Envoy 实例都会维护[负载均衡信息](/docs/concepts/traffic-management/load-balancing/)，负载均衡信息是基于从 Pilot 获得的信息，以及其负载均衡池中的其他实例的定期健康检查。从而允许其在目标实例之间智能分配流量，同时遵循其指定的路由规则。

## 流量管理的好处

使用 Istio 的流量管理模型，本质上是将流量与基础设施扩容解耦，让运维人员可以通过 Pilot 指定流量遵循什么规则，而不是执行哪些 pod/VM 应该接收流量——Pilot 和智能 Envoy 代理会帮我们搞定。因此，例如，您可以通过 Pilot 指定特定服务的 5％ 流量可以转到金丝雀版本，而不必考虑金丝雀部署的大小，或根据请求的内容将流量发送到特定版本。

{{< image width="85%" ratio="69.52%"
    link="/docs/concepts/traffic-management/overview/TrafficManagementOverview.svg"
    caption="Istio 中的流量管理">}}

将流量从基础设施扩展中解耦，这样就可以让 Istio 提供各种流量管理功能，这些功能在应用程序代码之外。除了 A/B 测试的动态[请求路由](/docs/concepts/traffic-management/request-routing/)，逐步推出和金丝雀发布之外，它还使用超时、重试和熔断器处理[故障恢复](/docs/concepts/traffic-management/handling-failures/)，最后还可以通过[故障注入](/docs/concepts/traffic-management/fault-injection/)来测试服务之间故障恢复策略的兼容性。这些功能都是通过在服务网格中部署的 Envoy sidecar/代理来实现的。

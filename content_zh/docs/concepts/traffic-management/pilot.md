---
title: Pilot
description: Pilot 组件简介，Pilot 负责在服务网格中对分布部署的 Envoy 代理服务器进行管理。
weight: 10
keywords: [traffic-management， pilot]
---

Pilot 负责对部署在 Istio 服务网格中的 Envoy 实例的生命周期进行管理。

{{< image width="60%" ratio="72.17%"
    link="../img/pilot/PilotAdapters.svg"
    caption="Pilot 架构"
    >}}

如上图所示，Istio 为部署在网格中的服务维护了一个独立于底层平台的规范的表达层。特定平台的适配器都需在这一模型规定下进行运作。例如，Pilot 中的 Kubernetes 适配器实现了必要的控制器，用来监控 Kubernetes API server 中的信息变更，这些信息包括 Pod 注册信息、Ingress 资源以及用于存储流量管理规则的第三方资源的更改等。这些数据会被翻译成为 Pilot 模型。Envoy 专属的配置就是在这一模型的基础上生成的。

Pilot 公开了用于[服务发现](https://www.envoyproxy.io/docs/envoy/latest/api-v1/cluster_manager/sds) 、[负载均衡池](https://www.envoyproxy.io/docs/envoy/latest/api-v1/cluster_manager/cds)和[路由表](https://www.envoyproxy.io/docs/envoy/latest/api-v1/route_config/rds)的动态更新的 API。这些 API 将 Envoy 从平台特有的细微差别中解脱出来，简化了设计并提升了跨平台的可移植性。

运维人员可以通过 [Pilot 的 Rules API](/docs/reference/config/istio.routing.v1alpha1/) 制定高级流量管理规则。这些规则被翻译成低级配置，并通过 discovery API 分发到 Envoy 实例。

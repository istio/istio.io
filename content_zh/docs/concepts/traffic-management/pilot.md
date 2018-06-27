---
title: Pilot
description: 介绍 Pilot，该组件负责部署在 Istio 服务网格中的 Envoy 实例的生命周期管理。
weight: 10
keywords: [traffic-management,pilot]
aliases:
    - /docs/concepts/traffic-management/manager.html
---

Pilot 负责部署在 Istio 服务网格中的 Envoy 实例的生命周期管理。

{{</* image width="60%" ratio="72.17%"
    link="../img/pilot/PilotAdapters.svg"
    caption="Pilot 架构"
    */>}}

如上图所示，Pilot 维护了网格中的服务的规范表示，这个表示是独立于底层平台的。Pilot 中的平台特定适配器负责适当填充此规范模型。例如，Pilot 中的 Kubernetes 适配器实现必要的控制器来 watch Kubernetes API server 中 pod 注册信息、ingress 资源以及用于存储流量管理规则的第三方资源的更改。该数据被翻译成规范表示。Envoy 特定配置是基于规范表示生成的。

Pilot 公开了用于[服务发现](https://www.envoyproxy.io/docs/envoy/latest/api-v1/cluster_manager/sds) 、[负载均衡池](https://www.envoyproxy.io/docs/envoy/latest/configuration/cluster_manager/cds)和[路由表](https://www.envoyproxy.io/docs/envoy/latest/configuration/http_conn_man/rds)的动态更新的 API。这些 API 将 Envoy 从平台特有的细微差别中解脱出来，简化了设计并提升了跨平台的可移植性。

运维人员可以通过 [Pilot 的 Rules API](/docs/reference/config/istio.routing.v1alpha1/)指定高级流量管理规则。这些规则被翻译成低级配置，并通过 discovery API 分发到 Envoy 实例。
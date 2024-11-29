---
title: 为什么我的请求没有被追踪？
weight: 30
---

在 `default` [配置文件](/zh/docs/setup/additional-setup/config-profiles/)中，
链路追踪的采样率被设置为 1%。这意味着 Istio 捕获的 100 个链路实例中只有 1 个会报告给跟踪后端。
`demo` 配置文件中的采样率设置为 100%。有关如何设置采样率的信息，
请参阅[本节](/zh/docs/tasks/observability/distributed-tracing/telemetry-api/#customizing-trace-sampling)。

如果您仍然没有看到任何追踪数据，请确认您的端口是否符合 Istio [端口命名规范](/zh/faq/traffic-management/#naming-port-convention)，
并公开适当的容器端口（例如，通过 pod spec）来启用 sidecar 代理（Envoy）能够对流量进行捕获。

如果您只看到与出口代理相关的链路数据，而没有看到入口代理，
则可能仍与 Istio [端口命名约定](/zh/about/faq/#naming-port-convention)有关。

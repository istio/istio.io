---
title: 为什么我的请求没有被追踪？
weight: 30
---

从 Istio 1.0.3 开始，其 `default` 追踪采样率已经降低到 1%。
[配置文件](/zh/docs/setup/additional-setup/config-profiles/)。
这意味着 Istio 捕获的 100 个追踪实例中只有 1 个将被报告给追踪后端。
`demo` 文件中的采样率仍设为 100%。
有关如何设置采样率的更多信息，可参见[本节](/zh/docs/tasks/observability/distributed-tracing/overview/#trace-sampling)。

如果您仍然没有看到任何追踪数据，请确认您的端口是否符合 Istio [端口命名规范](/zh/faq/traffic-management/#naming-port-convention)，
并公开适当的容器端口（例如，通过 pod spec）来启用 sidecar 代理（Envoy）能够对流量进行捕获。


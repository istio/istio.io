---
title: 如何使用 Istio 实现分布式追踪？
weight: 0
---

Istio 以两种不同的方式与分布式追踪系统集成:
[基于 Envoy 的](#how-envoy-based-tracing-works)和[基于 Mixer 的](#how-mixer-based-tracing-works)。
这两种追踪集成方法，都由[应用程序负责为后续传出请求转发追踪的 header 信息](#istio-copy-headers)。

您可以在 Istio 分布式追踪（[Jaeger](/zh/docs/tasks/telemetry/distributed-tracing/jaeger/)、[LightStep](/zh/docs/tasks/telemetry/distributed-tracing/lightstep/)、[Zipkin](/zh/docs/tasks/telemetry/distributed-tracing/zipkin/)）任务以及
[Envoy 追踪文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing) 中找到更多信息。

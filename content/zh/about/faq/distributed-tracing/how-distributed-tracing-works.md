---
title: 如何使用 Istio 实现分布式追踪？
weight: 0
---

Istio 使用 [Envoy](#how-envoy-based-tracing-works)的分布式追踪系统集成。由[应用程序负责为后续传出请求转发追踪的 header 信息](#istio-copy-headers)。

您可以在 Istio 分布式追踪（[Jaeger](/zh/docs/tasks/observability/distributed-tracing/jaeger/), [LightStep](/zh/docs/tasks/observability/distributed-tracing/lightstep/), [Zipkin](/zh/docs/tasks/observability/distributed-tracing/zipkin/)）任务以及 [Envoy 追踪文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing)中找到更多信息。

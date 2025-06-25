---
title: 基于 Envoy 的跟踪如何工作？
weight: 11
---

在基于 Envoy 的跟踪集成中，Envoy（Sidecar 代理）代表所代理的应用程序将跟踪信息直接发送到后端服务。

Envoy：

- 在请求代理时为请求生成请求 ID 和跟踪标头（例如 `X-B3-TraceId`）
- 根据请求和响应元数据（即响应时间）为每个请求生成跟踪范围
- 将生成的跟踪范围发送到跟踪后端
- 将跟踪头转发到代理的应用程序

Istio 支持 [OpenTelemetry](/zh/docs/tasks/observability/distributed-tracing/opentelemetry/)
和兼容的后端，包括 [Jaeger](/zh/docs/tasks/observability/distributed-tracing/jaeger/)。
其他支持的平台包括 [Zipkin](/zh/docs/tasks/observability/distributed-tracing/zipkin/)
和 [Apache SkyWalking](/zh/docs/tasks/observability/distributed-tracing/skywalking/)。

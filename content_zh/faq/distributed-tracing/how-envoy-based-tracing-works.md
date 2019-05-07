---
title: 基于 Envoy 的追踪是如何工作的？
weight: 11
---

对于基于 Envoy 的追踪，Envoy（sidecar 代理）直接将追踪信息发送给代表被代理应用程序的追踪后端。

Envoy：

- 当请求通过代理时生成请求 ID 和 追踪 header（例如，`X-B3-TraceId`）
- 基于请求和响应元数据信息（例如，响应时间）为每个请求生成追踪 span
- 发送生成的追踪 span 到追踪后端
- 将追踪 header 转发给被代理的应用程序

Istio 支持与基于 Envoy 的[LightStep](/zh/docs/tasks/telemetry/distributed-tracing/lightstep/)、[Zipkin](/zh/docs/tasks/telemetry/distributed-tracing/zipkin/) 进行追踪集成，也支持与所有 Zipkin API 兼容后端集成，包括 [Jaeger](/zh/docs/tasks/telemetry/distributed-tracing/jaeger/)。

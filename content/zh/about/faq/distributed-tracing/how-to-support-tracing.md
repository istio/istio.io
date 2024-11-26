---
title: 使用 Istio 进行分布式追踪需要什么？
weight: 10
---

Istio 允许报告服务网格中工作负载到工作负载间通信的追踪 Span。
然而，为了将各种追踪 Span 整合在一起以获得完整的流量图，应用程序必须在传入和传出请求之间传播追踪上下文信息。

具体来说，Istio 依靠应用程序来转发 Envoy 生成的请求 ID 和标准标头。这些标头包括：

- `x-request-id`
- `traceparent`
- `tracestate`

Zipkin 用户必须确保他们[传播 B3 链路追踪标头](https://github.com/openzipkin/b3-propagation)。

- `x-b3-traceid`
- `x-b3-spanId`
- `x-b3-parentspanid`
- `x-b3-sampled`
- `x-b3-flags`
- `b3`

标头传播可通过客户端库完成，例如 [OpenTelemetry](https://opentelemetry.io/docs/concepts/context-propagation/)。
它也可手动完成，如[分布式链路追踪任务](/zh/docs/tasks/observability/distributed-tracing/overview/#trace-context-propagation)中所述。

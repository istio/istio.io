---
title: 使用 Istio 进行分布式追踪需要什么？
weight: 10
---

Istio 允许报告服务网格中工作负载到工作负载间通信的追踪 span。
然而，为了将各种追踪 span 整合在一起以获得完整的流量图，应用程序必须在传入和传出请求之间传播追踪上下文信息。

特别是，Istio 依赖于应用程序[传播 B3 追踪 header](https://github.com/openzipkin/b3-propagation) 以及由 Envoy 生成的请求 ID。
这些 header 包括:

- `x-request-id`
- `x-b3-traceid`
- `x-b3-spanId`
- `x-b3-parentspanid`
- `x-b3-sampled`
- `x-b3-flags`
- `b3`

如果使用 LightStep，您还需要转发以下 header：

- `x-ot-span-context`

header 传播可以通过客户端库完成，例如 [Zipkin](https://zipkin.io/pages/existing_instrumentations.html) 或 [Jaeger](https://github.com/jaegertracing/jaeger-client-java/tree/master/jaeger-core#b3-propagation)。
当然，这也可以手动完成，正如[分布式追踪任务](/zh/docs/tasks/telemetry/distributed-tracing/overview/#understanding-what-happened)中所描述的那样。
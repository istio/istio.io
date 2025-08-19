---
title: How does Envoy-based tracing work?
weight: 11
---

For Envoy-based tracing integrations, Envoy (the sidecar proxy) sends tracing information directly to tracing backends on behalf of the applications being proxied.

Envoy:

- generates request IDs and trace headers (i.e., `X-B3-TraceId`) for requests as they flow through the proxy
- generates trace spans for each request based on request and response metadata (i.e., response time)
- sends the generated trace spans to the tracing backends
- forwards the trace headers to the proxied application

Istio supports [OpenTelemetry](/docs/tasks/observability/distributed-tracing/opentelemetry/) and compatible backends including [Jaeger](/docs/tasks/observability/distributed-tracing/jaeger/). Other supported platforms include [Zipkin](/docs/tasks/observability/distributed-tracing/zipkin/) and [Apache SkyWalking](/docs/tasks/observability/distributed-tracing/skywalking/).

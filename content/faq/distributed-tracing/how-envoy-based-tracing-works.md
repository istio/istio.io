---
title: How does Envoy-based tracing work?
weight: 11
---

For Envoy-based tracing integrations, Envoy (the sidecar proxy) sends tracing information directly to tracing backends on behalf of the applications being proxied.

Envoy:

- generates request IDs and trace headers (i.e. `X-B3-TraceId`) for requests as they flow through the proxy
- generates trace spans for each request based on request and response metadata (i.e. response time)
- sends the generated trace spans to the tracing backends
- forwards the trace headers to the proxied application

Istio supports the Envoy-based integrations of [LightStep](/docs/tasks/telemetry/distributed-tracing/lightstep/) and [Zipkin](/docs/tasks/telemetry/distributed-tracing/zipkin/), as well as all Zipkin API-compatible backends, including [Jaeger](/docs/tasks/telemetry/distributed-tracing/jaeger/).

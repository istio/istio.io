---
title: What is required for distributed tracing with Istio?
weight: 10
---

Istio enables reporting of trace spans for workload-to-workload communications within a mesh. However, in order for various trace spans to be stitched together for a complete view of the traffic flow, applications must propagate the trace context between incoming and outgoing requests.

In particular, Istio relies on applications to [propagate the B3 trace headers](https://github.com/openzipkin/b3-propagation), as well as the Envoy-generated request ID. These headers include:

- `x-request-id`
- `x-b3-traceid`
- `x-b3-spanId`
- `x-b3-parentspanid`
- `x-b3-sampled`
- `x-b3-flags`
- `b3`

If you are using LightStep, you will also need to forward the following headers:

- `x-ot-span-context`

Header propagation may be accomplished through client libraries, such as [Zipkin](https://zipkin.io/pages/tracers_instrumentation.html) or [Jaeger](https://github.com/jaegertracing/jaeger-client-java/tree/master/jaeger-core#b3-propagation). It may also be accomplished manually, as documented in the [Distributed Tracing Task](/docs/tasks/observability/distributed-tracing/overview#trace-context-propagation).
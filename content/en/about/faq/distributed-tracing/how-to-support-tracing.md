---
title: What is required for distributed tracing with Istio?
weight: 10
---

Istio enables reporting of trace spans for workload-to-workload communications within a mesh. However, in order for various trace spans to be stitched together for a complete view of the traffic flow, applications must propagate the trace context between incoming and outgoing requests.

In particular, Istio relies on applications to forward the Envoy-generated request ID, and standard headers. These headers include:

- `x-request-id`
- `traceparent`
- `tracestate`

 Zipkin users must ensure they [propagate the B3 trace headers](https://github.com/openzipkin/b3-propagation).

- `x-b3-traceid`
- `x-b3-spanid`
- `x-b3-parentspanid`
- `x-b3-sampled`
- `x-b3-flags`
- `b3`

Header propagation may be accomplished through client libraries, such as [OpenTelemetry](https://opentelemetry.io/docs/concepts/context-propagation/). It can also be accomplished manually, as documented in the [Distributed Tracing task](/docs/tasks/observability/distributed-tracing/overview/#trace-context-propagation).

---
title: How does Distributed Tracing work with Istio?
weight: 0
---

Istio integrates with distributed tracing systems in two different ways: Envoy-based and Mixer-based tracing integrations.

For Envoy-based tracing integrations, Envoy (the sidecar proxy) sends tracing information directly to tracing backends on behalf of the applications being proxied.

Envoy:

- generates request IDs and trace headers (i.e. `X-B3-TraceId`) for requests as they flow through the proxy
- generates trace spans for each request based on request and response metadata (i.e. response time)
- sends the generated trace spans to the tracing backends
- forwards the trace headers to the proxied application

Istio supports the Envoy-based integrations of [LightStep](/docs/tasks/telemetry/distributed-tracing/lightstep/) and [Zipkin](/docs/tasks/telemetry/distributed-tracing/zipkin/), as well as all Zipkin API-compatible backends, including [Jaeger](/docs/tasks/telemetry/distributed-tracing/jaeger/).

For Mixer-based tracing integrations, Mixer (addressed through the `istio-telemetry` service) provides the integration with tracing backends. The Mixer integration allows additional levels of operator control of the distributed tracing, including fine-grained selection of the data included in trace spans. It also provides the ability to send traces to backends not supported by Envoy directly.

For Mixer-based integrations, Envoy:

- generates request IDs and trace headers (i.e. `X-B3-TraceId`) for requests as they flow through the proxy
- calls Mixer for general asynchronous telemetry reporting
- forwards the trace headers to the proxied application

Mixer:

- generates trace spans for each request based on *operator-supplied* configuration
- sends the generated trace spans to the *operator-designated* tracing backends

The [Stackdriver tracing integration](https://cloud.google.com/istio/docs/istio-on-gke/installing#enabling_tracing) with Istio is one example of a tracing integration via Mixer.

For both tracing integration approaches, [applications are responsible for forwarding tracing headers](#istio-copy-headers) for subsequent outgoing requests.

You can find additional information in the Istio Distributed Tracing ([Jaeger](/docs/tasks/telemetry/distributed-tracing/jaeger/), [LightStep](/docs/tasks/telemetry/distributed-tracing/lightstep/), [Zipkin](/docs/tasks/telemetry/distributed-tracing/zipkin/)) Tasks and
in the [Envoy tracing docs](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/tracing#tracing).

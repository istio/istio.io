---
title: How does Mixer-based tracing work?
weight: 12
---

For Mixer-based tracing integrations, Mixer (addressed through the `istio-telemetry` service) provides the integration with tracing backends. The Mixer integration allows additional levels of operator control of the distributed tracing, including fine-grained selection of the data included in trace spans. It also provides the ability to send traces to backends not supported by Envoy directly.

For Mixer-based integrations, Envoy:

- generates request IDs and trace headers (i.e. `X-B3-TraceId`) for requests as they flow through the proxy
- calls Mixer for general asynchronous telemetry reporting
- forwards the trace headers to the proxied application

Mixer:

- generates trace spans for each request based on *operator-supplied* configuration
- sends the generated trace spans to the *operator-designated* tracing backends

The [Stackdriver tracing integration](https://cloud.google.com/istio/docs/istio-on-gke/installing#tracing_and_logging) with Istio is one example of a tracing integration via Mixer.

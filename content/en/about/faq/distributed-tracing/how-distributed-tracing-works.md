---
title: How does distributed tracing work with Istio?
weight: 0
---

Istio integrates with distributed tracing systems using [Envoy-based](#how-envoy-based-tracing-works) tracing. With Envoy-based tracing integration, [applications are responsible for forwarding tracing headers](#istio-copy-headers) for subsequent outgoing requests.

You can find additional information in the Istio Distributed Tracing ([Jaeger](/docs/tasks/observability/distributed-tracing/jaeger/), [Lightstep](/docs/tasks/observability/distributed-tracing/lightstep/), [Zipkin](/docs/tasks/observability/distributed-tracing/zipkin/)) Tasks and
in the [Envoy tracing docs](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing).

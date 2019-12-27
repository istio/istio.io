---
title: How does distributed tracing work with Istio?
weight: 0
---

Istio integrates with distributed tracing systems in two different ways: [Envoy-based](#how-envoy-based-tracing-works) and [Mixer-based](#how-mixer-based-tracing-works) tracing integrations. For both tracing integration approaches, [applications are responsible for forwarding tracing headers](#istio-copy-headers) for subsequent outgoing requests.

You can find additional information in the Istio Distributed Tracing ([Jaeger](/pt-br/docs/tasks/observability/distributed-tracing/jaeger/), [LightStep](/pt-br/docs/tasks/observability/distributed-tracing/lightstep/), [Zipkin](/pt-br/docs/tasks/observability/distributed-tracing/zipkin/)) Tasks and
in the [Envoy tracing docs](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing).

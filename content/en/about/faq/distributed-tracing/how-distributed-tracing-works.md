---
title: How does distributed tracing work with Istio?
weight: 0
---

Istio integrates with distributed tracing systems using [Envoy-based](#how-envoy-based-tracing-works) tracing. With Envoy-based tracing integration, [applications are responsible for forwarding tracing headers](#istio-copy-headers) for subsequent outgoing requests.

You can find additional information in the [Distributed Tracing overview](/docs/tasks/observability/distributed-tracing/overview/) and
in the [Envoy tracing docs](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing).

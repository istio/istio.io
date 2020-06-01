---
title: Jaeger
description: How to integrate with Jaeger.
weight: 28
keywords: [integration,jaeger,tracing]
test: n/a
---

[Jaeger](https://www.jaegertracing.io/) is an open source end to end distributed tracing system, allowing users to monitor and troubleshoot transactions in complex distributed systems.

## Configuration

Consult the [Jaeger documentation](https://www.jaegertracing.io/) to get started. No special changes are needed for Jaeger to work with Istio.

Once Jaeger is installed, you will need to point Istio proxies to send traces to the deployment. This can be configured with `--set values.global.tracer.zipkin.address=<jaeger-collector-address>:9411` at installation time. See the [`ProxyConfig.Tracing`](/docs/reference/config/istio.mesh.v1alpha1/#Tracing) for advanced configuration such as TLS settings.

## Usage

For more information on using Jaeger, please refer to the [Jaeger task](/docs/tasks/observability/distributed-tracing/jaeger/).

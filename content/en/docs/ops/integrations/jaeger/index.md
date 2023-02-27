---
title: Jaeger
description: How to integrate with Jaeger.
weight: 28
keywords: [integration,jaeger,tracing]
owner: istio/wg-environments-maintainers
test: n/a
---

{{< boilerplate telemetry-tracing-tips >}}

[Jaeger](https://www.jaegertracing.io/) is an open source end to end distributed tracing system, allowing users to monitor and troubleshoot transactions in complex distributed systems.

## Installation

### Option 1: Quick start

Istio provides a basic sample installation to quickly get Jaeger up and running:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/jaeger.yaml
{{< /text >}}

This will deploy Jaeger into your cluster. This is intended for demonstration only, and is not tuned for performance or security.

### Option 2: Customizable install

Consult the [Jaeger documentation](https://www.jaegertracing.io/) to get started. No special changes are needed for Jaeger to work with Istio.

Once Jaeger is installed, you will need to point Istio proxies to send traces to the deployment. This can be configured with `--set meshConfig.defaultConfig.tracing.zipkin.address=<jaeger-collector-address>:9411` at installation time. See the [`ProxyConfig.Tracing`](/docs/reference/config/istio.mesh.v1alpha1/#Tracing) for advanced configuration such as TLS settings.

## Usage

For more information on using Jaeger, please refer to the [Jaeger task](/docs/tasks/observability/distributed-tracing/jaeger/).

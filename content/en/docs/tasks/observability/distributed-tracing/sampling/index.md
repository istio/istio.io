---
title: Trace Sampling
description: Learn the different approaches on how to configure trace sampling on the proxies.
weight: 10
keywords: [sampling,telemetry,tracing,opentelemetry]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Istio provides multiple ways to configure trace sampling. In this page you will learn and understand
all the different ways sampling can be configured.

## Before you begin

1.  Ensure that your applications propagate tracing headers as described [here](/docs/tasks/observability/distributed-tracing/overview/).

## Available trace sampling configurations

1.  Percentage Sampler: A random sampling rate for percentage of requests that will be selected for trace
    generation.

1.  Custom OpenTelemetry Sampler: A custom sampler implementation, that must be paired with the `OpenTelemetryTracingProvider`.

1.  Deploy the OpenTelemetry Collector

    {{< boilerplate start-otel-collector-service >}}

### Percentage Sampler

{{< boilerplate telemetry-tracing-tips >}}

The random sampling rate percentage uses the specified percentage value to pick which requests to sample.

The sampling rate should be in the range of 0.0 to 100.0 with a precision of 0.01.
For example, to trace 5 requests out of every 10000, use 0.05 as the value here.

There are three ways you can configure the random sampling rate:

#### Globally via `MeshConfig`

Random percentage sampling can be configured globally via `MeshConfig`.

{{< text syntax=bash snip_id=install_default_sampling >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 10
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 4317
        service: opentelemetry-collector.observability.svc.cluster.local
        resource_detectors:
          environment: {}
EOF
{{< /text >}}

Then enable the tracing provider via Telemetry API. Note we don't set `randomSamplingPercentage` here.

{{< text syntax=bash snip_id=enable_telemetry_no_sampling >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: otel-tracing
EOF
{{< /text >}}

#### Pod annotation `proxy.istio.io/config`

You can add the `proxy.istio.io/config` annotation to your Pod metadata
specification to override any mesh-wide sampling settings.

For instance, to override the mesh-wide sampling above, you would add the following to your pod manifest:

{{< text syntax=yaml snip_id=none >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: curl
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        ...
        proxy.istio.io/config: |
          tracing:
            sampling: 20
    spec:
      ...
{{< /text >}}

#### Telemetry API

The random percentage sampler can also be configured via the Telemetry API.
Via the Telemetry API, sampling can be configured on various scopes: mesh-wide, namespace or workload, offering great flexibility.
To learn more, please see the [Telemetry API](/docs/tasks/observability/telemetry/) documentation.

Install Istio without setting `sampling` inside `defaultConfig`:

{{< text syntax=bash snip_id=install_without_sampling >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 4317
        service: opentelemetry-collector.observability.svc.cluster.local
        resource_detectors:
          environment: {}
EOF
{{< /text >}}

Then enable the tracing provider via Telemetry API and set the `randomSamplingPercentage`.

{{< text syntax=bash snip_id=enable_telemetry_with_sampling >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
   name: otel-demo
spec:
  tracing:
  - providers:
    - name: otel-tracing
    randomSamplingPercentage: 10
EOF
{{< /text >}}

### Custom OpenTelemetry Sampler

The OpenTelemetry specification defines the [Sampler API](https://github.com/open-telemetry/opentelemetry-specification/blob/v1.31.0/specification/trace/sdk.md#sampler).
The Sampler API enables building a custom sampler that can perform more intelligent and efficient sampling decisions,
such as [Probability Sampling](https://github.com/open-telemetry/opentelemetry-specification/blob/v1.31.0/specification/trace/tracestate-probability-sampling.md).

Such samplers can then be paired with the [`OpenTelemetryTracingProvider`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-OpenTelemetryTracingProvider).

{{< quote >}}
The sampler implementation resides in the proxy and can be found in
[Envoy OpenTelemetry Samplers](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/trace/opentelemetry/samplers#opentelemetry-samplers).
{{< /quote >}}

Current custom sampler configurations in Istio:

- [Dynatrace Sampler](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-OpenTelemetryTracingProvider-DynatraceSampler)

Custom samplers are configured via `Meshconfig`. Here is an example of configuring the Dynatrace sampler:

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 443
        service: abc.live.dynatrace.com/api/v2/otlp
        http:
          path: "/api/v2/otlp/v1/traces"
          timeout: 10s
          headers:
            - name: "Authorization"
              value: "Api-Token dt0c01."
        dynatrace_sampler:
          tenant: "abc"
          cluster_id: 123
{{< /text >}}

## Order of precedence

With multiple ways of configuring sampling, it is important to understand
the order of precedence of each method.

When using the random percentage sampler the order of precedence is:

`Telemetry API` > `Pod Annotation` > `MeshConfig`.

That means, if a value is defined in all of the above, the value on the `Telemetry API` is the one selected.

When a custom OpenTelemetry sampler is configured, the order of precedence is:

`Custom OTel Sampler` > (`Telemetry API` | `Pod Annotation` | `MeshConfig`)

That means, if a custom OpenTelemetry sampler is configured, it overrides all the others methods.
Additionally, the random percentage value is set to `100` and cannot be changed. This is important
because the custom sampler needs to receive 100% of spans to be able to properly perform its decision.

## Deploy the Bookinfo Application

Deploy the [Bookinfo](/docs/examples/bookinfo/#deploying-the-application) sample application.

## Generating traces using the Bookinfo sample

1.  When the Bookinfo application is up and running, access `http://$GATEWAY_URL/productpage`
    one or more times to generate trace information.

    {{< boilerplate trace-generation >}}

## Cleanup

1.  Remove the Telemetry resource:

    {{< text syntax=bash snip_id=cleanup_telemetry >}}
    $ kubectl delete telemetry otel-demo
    {{< /text >}}

1.  Remove any `istioctl` processes that may still be running using control-C or:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}

1.  Uninstall the OpenTelemetry Collector:

    {{< text syntax=bash snip_id=cleanup_collector >}}
    $ kubectl delete -f @samples/open-telemetry/otel.yaml@ -n observability
    $ kubectl delete namespace observability
    {{< /text >}}

---
title: OpenTelemetry
description: Learn how to configure the proxies to send OpenTelemetry traces to a Collector.
weight: 10
keywords: [telemetry,tracing,opentelemetry,span,port-forwarding]
aliases:
 - /docs/tasks/telemetry/distributed-tracing/opentelemetry/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

After completing this task, you will understand how to have your application participate in tracing with [OpenTelemetry](https://www.opentelemetry.io/), regardless of the language, framework, or platform you use to build your application.

This task uses the [Bookinfo](/docs/examples/bookinfo/) sample as the example application and the
[OpenTelemetry Collector](https://opentelemetry.io/docs/collector/) as the receiver of traces.

To learn how Istio handles tracing, visit this task's [overview](../overview/).

## Deploy the OpenTelemetry Collector

{{< boilerplate start-otel-collector-service >}}

## Installation

All tracing options can be configured globally via `MeshConfig`.
To simplify configuration, it is recommended to create a single YAML file
which you can pass to the `istioctl install -f` command.

## Choosing the exporter

Istio can be configured to export [OpenTelemetry Protocol (OTLP)](https://opentelemetry.io/docs/specs/otel/protocol/)
traces via gRPC or HTTP. Only one exporter can be configured at a time (either gRPC or HTTP).

### Exporting via gRPC

In this example, traces will be exported via OTLP/gRPC to the OpenTelemetry Collector.
The example also enables the [environment resource detector](https://opentelemetry.io/docs/languages/js/resources/#adding-resources-with-environment-variables). The environment detector adds attributes from the environment variable
`OTEL_RESOURCE_ATTRIBUTES` to the exported OpenTelemetry resource.

{{< text syntax=bash snip_id=none >}}
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

### Exporting via HTTP

In this example, traces will be exported via OTLP/HTTP to the OpenTelemetry Collector.
The example also enables the [environment resource detector](https://opentelemetry.io/docs/languages/js/resources/#adding-resources-with-environment-variables). The environment detector adds attributes from the environment variable
`OTEL_RESOURCE_ATTRIBUTES` to the exported OpenTelemetry resource.

{{< text syntax=bash snip_id=install_otlp_http >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 4318
        service: opentelemetry-collector.observability.svc.cluster.local
        http:
          path: "/v1/traces"
          timeout: 5s
          headers:
            - name: "custom-header"
              value: "custom value"
        resource_detectors:
          environment: {}
EOF
{{< /text >}}

## Enable tracing for mesh via Telemetry API

Enable tracing by applying the following configuration:

{{< text syntax=bash snip_id=enable_telemetry >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: otel-demo
spec:
  tracing:
  - providers:
    - name: otel-tracing
    randomSamplingPercentage: 100
    customTags:
      "my-attribute":
        literal:
          value: "default-value"
EOF
{{< /text >}}

## Deploy the Bookinfo Application

Deploy the [Bookinfo](/docs/examples/bookinfo/#deploying-the-application) sample application.

## Generating traces using the Bookinfo sample

1.  When the Bookinfo application is up and running, access `http://$GATEWAY_URL/productpage`
    one or more times to generate trace information.

    {{< boilerplate trace-generation >}}

1.  The OpenTelemetry Collector used in the example is configured to export traces to the console.
    If you used the example Collector config, you can verify traces are arriving by looking
    at the Collector logs. It should contain something like:

    {{< text syntax=yaml snip_id=none >}}
    Resource SchemaURL:
    Resource labels:
          -> service.name: STRING(productpage.default)
    ScopeSpans #0
    ScopeSpans SchemaURL:
    InstrumentationScope
    Span #0
        Trace ID       : 79fb7b59c1c3a518750a5d6dad7cd2d1
        Parent ID      : 0cf792b061f0ad51
        ID             : 2dff26f3b4d6d20f
        Name           : egress reviews:9080
        Kind           : SPAN_KIND_CLIENT
        Start time     : 2024-01-30 15:57:58.588041 +0000 UTC
        End time       : 2024-01-30 15:57:59.451116 +0000 UTC
        Status code    : STATUS_CODE_UNSET
        Status message :
    Attributes:
          -> node_id: STRING(sidecar~10.244.0.8~productpage-v1-564d4686f-t6s4m.default~default.svc.cluster.local)
          -> zone: STRING()
          -> guid:x-request-id: STRING(da543297-0dd6-998b-bd29-fdb184134c8c)
          -> http.url: STRING(http://reviews:9080/reviews/0)
          -> http.method: STRING(GET)
          -> downstream_cluster: STRING(-)
          -> user_agent: STRING(curl/7.74.0)
          -> http.protocol: STRING(HTTP/1.1)
          -> peer.address: STRING(10.244.0.8)
          -> request_size: STRING(0)
          -> response_size: STRING(441)
          -> component: STRING(proxy)
          -> upstream_cluster: STRING(outbound|9080||reviews.default.svc.cluster.local)
          -> upstream_cluster.name: STRING(outbound|9080||reviews.default.svc.cluster.local)
          -> http.status_code: STRING(200)
          -> response_flags: STRING(-)
          -> istio.namespace: STRING(default)
          -> istio.canonical_service: STRING(productpage)
          -> istio.mesh_id: STRING(cluster.local)
          -> istio.canonical_revision: STRING(v1)
          -> istio.cluster_id: STRING(Kubernetes)
          -> my-attribute: STRING(default-value)
    {{< /text >}}

## Cleanup

1.  Remove the Telemetry resource:

    {{< text syntax=bash snip_id=cleanup_telemetry >}}
    $ kubectl delete telemetry otel-demo
    {{< /text >}}

1.  Remove any `istioctl` processes that may still be running using control-C or:

    {{< text syntax=bash snip_id=none >}}
    $ killall istioctl
    {{< /text >}}

1.  Uninstall the OpenTelemetry Collector:

    {{< text syntax=bash snip_id=cleanup_collector >}}
    $ kubectl delete -f @samples/open-telemetry/otel.yaml@ -n observability
    $ kubectl delete namespace observability
    {{< /text >}}

1.  If you are not planning to explore any follow-on tasks, refer to the
    [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
    to shutdown the application.

---
title: Overview
description: Overview of distributed tracing in Istio.
weight: 1
keywords: [telemetry,tracing]
aliases:
 - /docs/tasks/telemetry/distributed-tracing/overview/
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

Distributed tracing enables users to track a request through mesh that is distributed across multiple services.
This allows a deeper understanding about request latency, serialization and parallelism via visualization.

Istio leverages [Envoy's distributed tracing](https://www.envoyproxy.io/docs/envoy/v1.12.0/intro/arch_overview/observability/tracing) feature to provide tracing integration out of the box.
Specifically, Istio provides options to install various tracing backends and configure proxies to send trace spans to them automatically. See [Zipkin](/docs/tasks/observability/distributed-tracing/zipkin/), [Jaeger](/docs/tasks/observability/distributed-tracing/jaeger/), [Lightstep](/docs/tasks/observability/distributed-tracing/lightstep/), and [OpenCensus Agent](/docs/tasks/observability/distributed-tracing/opencensusagent/) task docs about how Istio works with those tracing systems.

## Trace context propagation

Although Istio proxies can automatically send spans, extra information is needed to join those spans into a single trace. Applications must propagate this information in HTTP headers, so that when proxies send spans, the backend can join them together into a single trace.

To do this, each application must collect headers from each incoming request and forward the headers to all outgoing requests triggered by that incoming request. The choice of headers to forward depends on the configured trace backend. The set of headers to forward are described in each trace backend-specific task page. The following is a summary:

All applications should forward the following header:

* `x-request-id`: this is an envoy-specific header that is used to consistently sample logs and traces.

For Zipkin, Jaeger, Stackdriver, and OpenCensus Agent the B3 multi-header format should be forwarded:

* `x-b3-traceid`
* `x-b3-spanid`
* `x-b3-parentspanid`
* `x-b3-sampled`
* `x-b3-flags`

These are supported by Zipkin, Jaeger, OpenCensus, and many other tools.

For Datadog, the following headers should be forwarded. Forwarding these is handled automatically by Datadog client libraries for many languages and frameworks.

* `x-datadog-trace-id`.
* `x-datadog-parent-id`.
* `x-datadog-sampling-priority`.

For Lightstep, the OpenTracing span context header should be forwarded:

* `x-ot-span-context`

For Stackdriver and OpenCensus Agent, you can choose to use any one of the following headers instead of the B3 multi-header format.

* `grpc-trace-bin`: Standard grpc trace header.
* `traceparent`: W3C Trace Context standard for tracing. Supported by all OpenCensus, OpenTelemetry, and an increasing number of Jaeger client libraries.
* `x-cloud-trace-context`: used by Google Cloud product APIs.

If you look at the sample Python `productpage` service, for example, you see that the application extracts the required headers for all tracers from an HTTP request using [OpenTracing](https://opentracing.io/) libraries:

{{< text python >}}
def getForwardHeaders(request):
    headers = {}

    # x-b3-*** headers can be populated using the opentracing span
    span = get_current_span()
    carrier = {}
    tracer.inject(
        span_context=span.context,
        format=Format.HTTP_HEADERS,
        carrier=carrier)

    headers.update(carrier)

    # ...

        incoming_headers = ['x-request-id',
        'x-ot-span-context',
        'x-datadog-trace-id',
        'x-datadog-parent-id',
        'x-datadog-sampling-priority',
        'traceparent',
        'tracestate',
        'x-cloud-trace-context',
        'grpc-trace-bin',
        'user-agent',
        'cookie',
        'authorization',
        'jwt',
    ]

    # ...

    for ihdr in incoming_headers:
        val = request.headers.get(ihdr)
        if val is not None:
            headers[ihdr] = val

    return headers
{{< /text >}}

The reviews application (Java) does something similar using `requestHeaders`:

{{< text java >}}
@GET
@Path("/reviews/{productId}")
public Response bookReviewsById(@PathParam("productId") int productId, @Context HttpHeaders requestHeaders) {

  // ...

  if (ratings_enabled) {
    JsonObject ratingsResponse = getRatings(Integer.toString(productId), requestHeaders);
{{< /text >}}

When you make downstream calls in your applications, make sure to include these headers.

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

Istio leverages [Envoy's distributed tracing](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing) feature to provide tracing integration out of the box.

Most tracing backends now accept [OpenTelemetry](/docs/tasks/observability/distributed-tracing/opentelemetry/) protocol to receive traces, though Istio also supports legacy protocols for projects like [Zipkin](/docs/tasks/observability/distributed-tracing/zipkin/) and [Apache SkyWalking](/docs/tasks/observability/distributed-tracing/skywalking/).

## Configuring tracing

Istio provides a [Telemetry API](/docs/tasks/observability/distributed-tracing/telemetry-api/) which can be used to configure distributed tracing, including selecting a provider, setting [sampling rate](/docs/tasks/observability/distributed-tracing/sampling/) and header modification.

## Extension providers

[Extension providers](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider) are defined in `MeshConfig`, and allow defining the configuration for a trace backend. Supported providers are OpenTelemetry, Zipkin, SkyWalking, Datadog and Stackdriver.

## Building applications to support trace context propagation

Although Istio proxies can automatically send spans, extra information is needed to join those spans into a single trace. Applications must propagate this information in HTTP headers, so that when proxies send spans, the backend can join them together into a single trace.

To do this, each application must collect headers from each incoming request and forward the headers to all outgoing requests triggered by that incoming request. The choice of headers to forward depends on the configured trace backend. The set of headers to forward are described in each trace backend-specific task page. The following is a summary:

All applications should forward the following headers:

* `x-request-id`: an Envoy-specific header that is used to consistently sample logs and traces.
* `traceparent` and `tracestate`: [W3C standard headers](https://www.w3.org/TR/trace-context/)

For Zipkin, the [B3 multi-header format](https://github.com/openzipkin/b3-propagation) should be forwarded:

* `x-b3-traceid`
* `x-b3-spanid`
* `x-b3-parentspanid`
* `x-b3-sampled`
* `x-b3-flags`

For commercial observability tools, refer to their documentation.

If you look at the [sample Python `productpage` service]({{< github_blob >}}/samples/bookinfo/src/productpage/productpage.py#L125), for example, you see that the application extracts the required headers for all tracers from an HTTP request using OpenTelemetry libraries:

{{< text python >}}
def getForwardHeaders(request):
    headers = {}

    # x-b3-*** headers can be populated using the OpenTelemetry span
    ctx = propagator.extract(carrier={k.lower(): v for k, v in request.headers})
    propagator.inject(headers, ctx)

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

The [reviews application]({{< github_blob >}}/samples/bookinfo/src/reviews/reviews-application/src/main/java/application/rest/LibertyRestEndpoint.java#L186) (Java) does something similar using `requestHeaders`:

{{< text java >}}
@GET
@Path("/reviews/{productId}")
public Response bookReviewsById(@PathParam("productId") int productId, @Context HttpHeaders requestHeaders) {

  // ...

  if (ratings_enabled) {
    JsonObject ratingsResponse = getRatings(Integer.toString(productId), requestHeaders);
{{< /text >}}

When you make downstream calls in your applications, make sure to include these headers.

---
title: 概述
description: Istio 分布式追踪的概述。
weight: 1
keywords: [telemetry,tracing]
aliases:
 - /zh/docs/tasks/telemetry/distributed-tracing/overview/
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

分布式追踪可以让用户对跨多个分布式服务网格的 1 个请求进行追踪分析。
进而可以通过可视化的方式更加深入地了解请求的延迟，序列化和并行度。

Istio 利用 [Envoy 的分布式追踪](https://www.envoyproxy.io/docs/envoy/v1.12.0/intro/arch_overview/observability/tracing)功能提供了开箱即用的追踪集成。
确切地说，Istio 提供了安装各种追踪后端服务的选项，并且通过配置代理来自动发送追踪 Span 到分布式追踪系统服务。
请参阅 [Zipkin](/zh/docs/tasks/observability/distributed-tracing/zipkin/)、
[Jaeger](/zh/docs/tasks/observability/distributed-tracing/jaeger/)、
[Lightstep](/zh/docs/tasks/observability/distributed-tracing/lightstep/) 和
[OpenCensus Agent](/zh/docs/tasks/observability/distributed-tracing/opencensusagent/)
的任务文档来了解 Istio 如何与这些分布式追踪系统一起工作。

## 追踪上下文传递{#trace-context-propagation}

尽管 Istio 代理能够自动发送 Span，但需要一些附加信息才能将这些 Span 加到同一个调用链。
所以当代理发送 Span 信息的时候，应用程序需要附加适当的 HTTP 请求头信息，这样才能够把多个
Span 加到同一个调用链。

要做到这一点，每个应用程序必须从每个传入的请求中收集请求头，并将这些请求头转发到传入请求所触发的所有传出请求。
具体选择转发哪些请求头取决于所配置的跟踪后端。要转发到请求头的设置在每个追踪系统特定的任务页面进行说明。
以下是一个汇总：

所有应用程序必须转发以下请求头：

* `x-request-id`：这是 Envoy 专用的请求头，用于对日志和追踪进行一致的采样。

对于 Zipkin、Jaeger、Stackdriver 和 OpenCensus Agent，应转发 B3 多请求头格式：

* `x-b3-traceid`
* `x-b3-spanid`
* `x-b3-parentspanid`
* `x-b3-sampled`
* `x-b3-flags`

这些是 Zipkin、Jaeger、OpenCensus 和许多其他工具支持的请求头。

对于 Datadog，应转发以下请求头。对于许多语言和框架而言，这些转发由 Datadog 客户端库自动处理。

* `x-datadog-trace-id`
* `x-datadog-parent-id`
* `x-datadog-sampling-priority`

对于 Lightstep，应转发 OpenTracing span 上下文请求头：

* `x-ot-span-context`

对于 Stackdriver 和 OpenCensus Agent，您可以使用以下任一请求头来替代 B3 多请求头格式。

* `grpc-trace-bin`：标准的 grpc 追踪头。
* `traceparent`：追踪所用的 W3C 追踪上下文标准。受所有 OpenCensus、OpenTelemetry
  和日益增加的 Jaeger 客户端库所支持。
* `x-cloud-trace-context`：由 Google Cloud 产品 API 使用。

例如，如果您看 Python 的 `productpage` 服务这个例子，可以看到这个应用程序使用了
[OpenTracing](https://opentracing.io/) 库从 HTTP 请求中提取所需的头信息：

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

在 Review 这个应用中（Java）使用 `requestHeaders` 做了类似的事情：

{{< text java >}}
@GET
@Path("/reviews/{productId}")
public Response bookReviewsById(@PathParam("productId") int productId, @Context HttpHeaders requestHeaders) {

  // ...

  if (ratings_enabled) {
    JsonObject ratingsResponse = getRatings(Integer.toString(productId), requestHeaders);
{{< /text >}}

当您在应用程序中进行下游调用时，请确保包含这些请求头。

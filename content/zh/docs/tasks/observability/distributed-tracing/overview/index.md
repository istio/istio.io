---
title: 概述
description: Istio 分布式链路追踪的概述。
weight: 1
keywords: [telemetry,tracing]
aliases:
 - /zh/docs/tasks/telemetry/distributed-tracing/overview/
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

分布式链路追踪可以让用户对跨多个分布式服务网格的 1 个请求进行追踪分析。
进而可以通过可视化的方式更加深入地了解请求的延迟、序列化和并行度。

Istio 利用 [Envoy 的分布式链路追踪](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing)功能提供开箱即用的链路追踪集成。

现在，大多数链路追踪后端都接受
[OpenTelemetry](/zh/docs/tasks/observability/distributed-tracing/opentelemetry/) 协议来接收链路，
但 Istio 还支持 [Zipkin](/zh/docs/tasks/observability/distributed-tracing/zipkin/)
和 [Apache SkyWalking](/zh/docs/tasks/observability/distributed-tracing/skywalking/) 等项目的传统协议。

## 配置链路追踪 {#configuring-tracing}

Istio 提供了 [Telemetry API](/zh/docs/tasks/observability/distributed-tracing/telemetry-api/)，
可用于配置分布式链路追踪，包括选择提供商、
设置[采样率](/zh/docs/tasks/observability/distributed-tracing/sampling/)和修改标头。

## 扩展提供程序 {#extension-providers}

[扩展提供程序](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider)在 `MeshConfig` 中定义，
并允许定义链路追踪后端的配置。支持的提供程序包括 OpenTelemetry、Zipkin、SkyWalking、Datadog 和 Stackdriver。

## 构建应用程序以支持链路上下文传播 {#building-applications-to-support-trace-context-propagation}

尽管 Istio 代理能够自动发送 span，但需要一些附加信息才能将这些 span 加到同一个调用链。
所以当代理发送 span 信息的时候，应用程序需要附加适当的 HTTP 请求头信息，这样才能够把多个
span 加到同一个调用链。

要做到这一点，每个应用程序必须从每个传入的请求中收集请求头，并将这些请求头转发到传入请求所触发的所有传出请求中。
具体选择转发哪些请求头取决于所配置的链路追踪后端，要转发的请求头在每个链路追踪系统特定的任务页面进行说明，
以下是一个汇总：

所有应用程序必须转发以下请求头：

* `x-request-id`：一个 Envoy 特定的标头，用于一致地采样日志和链路。
* `traceparent` 和 `tracestate`：[W3C 标准标头](https://www.w3.org/TR/trace-context/)

对于 Zipkin，应转发 [B3 多标头格式](https://github.com/openzipkin/b3-propagation)：

* `x-b3-traceid`
* `x-b3-spanid`
* `x-b3-parentspanid`
* `x-b3-sampled`
* `x-b3-flags`

对于商业可观察性工具，请参阅其文档。

例如，如果你查看[示例 Python `productpage` 服务]({{< github_blob >}}/samples/bookinfo/src/productpage/productpage.py#L125)，
你会看到应用程序使用 OpenTelemetry 库从 HTTP 请求中提取所有链路追踪器所需的标头：

{{< text python >}}
def getForwardHeaders(request):
    headers = {}

    # 可以使用 OpenTelemetry 跨度填充 x-b3-*** 标头
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

在 [reviews 应用程序]({{< github_blob >}}/samples/bookinfo/src/reviews/reviews-application/src/main/java/application/rest/LibertyRestEndpoint.java#L186) (Java) 中使用 `requestHeaders` 做了类似的事情：

{{< text java >}}
@GET
@Path("/reviews/{productId}")
public Response bookReviewsById(@PathParam("productId") int productId, @Context HttpHeaders requestHeaders) {

  // ...

  if (ratings_enabled) {
    JsonObject ratingsResponse = getRatings(Integer.toString(productId), requestHeaders);
{{< /text >}}

当您在应用程序中进行下游调用时，请确保包含这些请求头。

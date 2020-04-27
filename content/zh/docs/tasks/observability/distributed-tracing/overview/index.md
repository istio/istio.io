---
title: 概述
description: Istio 分布式追踪的概述。
weight: 1
keywords: [telemetry,tracing]
aliases:
 - /zh/docs/tasks/telemetry/distributed-tracing/overview/
---

分布式追踪可以让用户对跨多个分布式服务网格的 1 个请求进行追踪分析。这样进而可以通过可视化的方式更加深入地了解请求的延迟，序列化和并行度。

Istio 利用 [Envoy 的分布式追踪](https://www.envoyproxy.io/docs/envoy/v1.10.0/intro/arch_overview/tracing)功能提供了开箱即用的追踪集成。确切地说，Istio 提供了安装各种各种追踪后端服务的选项，并且通过配置代理来自动发送追踪 span 到追踪后端服务。

请参阅 [Zipkin](../zipkin/)，[Jaeger](../jaeger/) 和 [LightStep](/zh/docs/tasks/observability/distributed-tracing/lightstep/) 的任务文档来了解 Istio 如何与这些分布式追踪系统一起工作。

## 追踪上下文传递{#trace-context-propagation}

尽管 Istio 代理能够自动发送 span，但是他们需要一些附加线索才能将整个追踪链路关联到一起。

所以当代理发送 span 信息的时候，应用需要附加适当的 HTTP 请求头信息，这样才能够把多个 span 正确的关联到同一个追踪上。

要做到这一点，应用程序从传入请求到任何传出的请求中需要包含以下请求头参数：

* `x-request-id`
* `x-b3-traceid`
* `x-b3-spanid`
* `x-b3-parentspanid`
* `x-b3-sampled`
* `x-b3-flags`
* `x-ot-span-context`

例如，如果你看 Python 的 `productpage` 服务这个例子，可以看到这个应用程序使用了 [OpenTracing](https://opentracing.io/) 库从 HTTP 请求中提取所需的头信息：

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

    incoming_headers = ['x-request-id']

    # ...

    for ihdr in incoming_headers:
        val = request.headers.get(ihdr)
        if val is not None:
            headers[ihdr] = val

    return headers
{{< /text >}}

在 reviews 这个应用中（Java）也做了类似的事情：

{{< text java >}}
@GET
@Path("/reviews/{productId}")
public Response bookReviewsById(@PathParam("productId") int productId,
                            @HeaderParam("end-user") String user,
                            @HeaderParam("x-request-id") String xreq,
                            @HeaderParam("x-b3-traceid") String xtraceid,
                            @HeaderParam("x-b3-spanid") String xspanid,
                            @HeaderParam("x-b3-parentspanid") String xparentspanid,
                            @HeaderParam("x-b3-sampled") String xsampled,
                            @HeaderParam("x-b3-flags") String xflags,
                            @HeaderParam("x-ot-span-context") String xotspan) {

  if (ratings_enabled) {
    JsonObject ratingsResponse = getRatings(Integer.toString(productId), user, xreq, xtraceid, xspanid, xparentspanid, xsampled, xflags, xotspan);
{{< /text >}}

当你在应用程序中进行下游调用时，请确保包含这些请求头。

## 追踪采样{#trace-sampling}

默认情况下，使用 demo 配置文件安装时，Istio 会捕获所有请求的追踪信息。例如，当使用上面的 Bookinfo 示例应用时，每次访问 `/productpage` 接口时，你都可以在 dashboard 中看到一条相应的追踪信息。此采样频率适用于测试或低流量网格。对于高流量网格你可以通过下面的两种方法之一来降低追踪采样频率：

* 在网格安装时，使用可选项 `values.pilot.traceSampling` 来设置采样百分比。参考[通过 {{< istioctl >}} 安装](/zh/docs/setup/install/istioctl/)文档查看详细的配置可选项。

* 在运行中的网格，可以通过编辑 `istio-pilot` deployment 并通过以下步骤来改变环境变量：
    1. 运行下面的命令来打开编辑器并加载 deployment 配置文件：

        {{< text bash >}}
        $ kubectl -n istio-system edit deploy istio-pilot
        {{< /text >}}

    1. 找到 `PILOT_TRACE_SAMPLING` 环境变量，将 `value:` 设置成你想要的百分比。

在这两种情况下，有效值的范围从 0.0 到 100.0，精度为 0.01。

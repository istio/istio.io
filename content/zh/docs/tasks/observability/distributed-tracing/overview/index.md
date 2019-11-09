---
title: 概述
description: Istio 中的分布式追踪概述。
weight: 1
keywords: [telemetry,tracing]
aliases:
 - zh/docs/tasks/telemetry/distributed-tracing/overview/
---

分布式追踪使用户可以通过跨多个服务的网格方式来追踪请求。进而可以通过可视化更深入地了解请求延迟，序列化和并行性。

Istio 利用 [Envoy 的分布式追踪特性](https://www.envoyproxy.io/docs/envoy/v1.10.0/intro/arch_overview/tracing)提供了开箱即用的追踪集成功能。具体来说，Istio 提供了安装不同的 tracing backend，并且通过配置代理的方式向 tracing backend 自动发送追踪的 spans 信息。

详情请参考 [Zipkin](../zipkin/)，[Jaeger](../jaeger/) 和 [LightStep](/docs/tasks/observability/distributed-tracing/lightstep/) 任务文档来了解 Istio 如何与这些分布式追踪系统协作的。

## 追踪上下文传递{#Trace-context-propagation}

尽管 Istio 代理能够自动发送 spans，但是他们需要一些附加信息才能将整个追踪链路关联起来。

应用需要传递一些附加的 HTTP 请求头信息以使得 Istio 代理在发送 span 信息时，能够将多个 span 正确的关联到同一个 trace 上。

为此，应用程序需要包含以下请求头参数，并在请求调用的过程中传递这些参数：

* `x-request-id`
* `x-b3-traceid`
* `x-b3-spanid`
* `x-b3-parentspanid`
* `x-b3-sampled`
* `x-b3-flags`
* `x-ot-span-context`

例如，如果你查看示例中的 Python 版的 productpage 服务，你能够看到应用中使用了 OpenTracing 库从 HTTP 请求头中提取出所需的参数信息：

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

在 reviews 应用中（Java）也做了类似的事情：

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

当你在应用中调用下游服务时，确保包含这些请求头信息。

## 追踪采样{#Trace-sampling}

默认情况下，使用演示中的配置文件安装时，Istio 捕获每一个请求的链路追踪信息。
例如，当使用上面提到的 Bookinfo 示例应用时，每次你访问 /productpage 接口时，你能够在 dashboard 中看到一条对应的 trace。这种情况下的采样率适合测试环境或者低流量的网格中。对于高流量的网格你可以通过以下两种方式任何一种来降低采样率：

* 在网格安装期间，使用可选项 `values.pilot.traceSampling` 来设置采样率。详情请参考
  [ {{<istioctl>}}](/docs/setup/install/operator/) 文档查看配置可选项的详细信息。
  
* 在运行的网格中，通过编辑`istio-pilot`部署文件并通过一下步骤来改变环境变量信息：
  
  1. 运行下面的命令，以文本编辑器的方式打开部署配置文件：
    

{{< text bash >}}
    $ kubectl -n istio-system edit deploy istio-pilot
{{< /text >}}
       

    1. 找到 `PILOT_TRACE_SAMPLING` 环境变量，将值设置成你期望的百分比。

在这两种情况下，有效值范围从 0.0 到 100.0，精度为 0.01。



---
title: 概述
description: Istio 分布式追踪概述。
weight: 1
keywords: [telemetry,tracing]
---

在完成这个任务后，您将了解如何将应用加入追踪，而不用关心其语言、框架或者您构建应用的平台。

这个任务使用 [Bookinfo](/zh/docs/examples/bookinfo/) 作为示例应用程序。

## 了解发生了什么 {#trace-context-propagation}

虽然 Istio 代理能够自动发送 span，但仍然需要一些线索来将整个追踪衔接起来。应用程序需要分发合适的 HTTP header，以便当代理发送 span 信息时，span 可以被正确的关联到一个追踪中。

为此，应用程序需要收集传入请求中的 header，并将其传播到任何传出请求。header 如下所示：

* `x-request-id`
* `x-b3-traceid`
* `x-b3-spanid`
* `x-b3-parentspanid`
* `x-b3-sampled`
* `x-b3-flags`
* `x-ot-span-context`

如果您查看示例服务，可以看到 `productpage` service（Python）从 HTTP 请求中提取所需的 header：

{{< text python >}}
def getForwardHeaders(request):
    headers = {}

    if 'user' in session:
        headers['end-user'] = session['user']

    incoming_headers = [ 'x-request-id',
                         'x-b3-traceid',
                         'x-b3-spanid',
                         'x-b3-parentspanid',
                         'x-b3-sampled',
                         'x-b3-flags',
                         'x-ot-span-context'
    ]

    for ihdr in incoming_headers:
        val = request.headers.get(ihdr)
        if val is not None:
            headers[ihdr] = val
            #print "incoming: "+ihdr+":"+val

    return headers
{{< /text >}}

reviews 应用程序（Java）做了类似的事情：

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
  int starsReviewer1 = -1;
  int starsReviewer2 = -1;

  if (ratings_enabled) {
    JsonObject ratingsResponse = getRatings(Integer.toString(productId), user, xreq, xtraceid, xspanid, xparentspanid, xsampled, xflags, xotspan);
{{< /text >}}

在应用程序中进行下游调用时，请确保包含了这些 header。

## 追踪采样 {#trace-sampling}

Istio 默认捕获所有请求的追踪信息。例如，当使用上面的 Bookinfo 示例应用程序时，每次访问 `/productpage` 时，都会看到相应的追踪仪表板。此采样率适用于测试或低流量网格。对于高流量网格，您可以以两种方式之一来降低追踪采样百分比：

* 在安装网格时，使用 `pilot.traceSampling` Helm 选项来设置追踪采样百分比。请查看 [Helm 安装](/zh/docs/setup/kubernetes/install/helm/)文档获取配置选项的详细信息。
* 在一个运行中的网格中，编辑 `istio-pilot` deployment，通过下列步骤改变环境变量：

    1. 运行以下命令打来文本编辑器并加载 deployment 配置文件：

        {{< text bash >}}
        $ kubectl -n istio-system edit deploy istio-pilot
        {{< /text >}}

    1. 找到 `PILOT_TRACE_SAMPLING` 环境变量，并修改 `value:` 为期望的百分比。

在这两种情况下，有效值都是 0.0 到 100.0，精度为 0.01。

---
title: 分布式跟踪
description: 如何进行代理配置将跟踪请求发送给 Zipkin 或 Jaeger。
weight: 10
keywords: [遥测,跟踪]
---

本文任务演示如何让 Istio 网格中的应用能够进行跟踪 Span 的收集。完成这一任务之后，读者会理解所有关于应用的先决条件，以便将应用加入跟踪过程。这一过程对实现应用的语言、架构以及平台等并无关联。

本例中会使用 [Bookinfo](/zh/docs/examples/bookinfo/) 作为示例应用。

## 开始之前

* 遵循[安装指南](/zh/docs/setup/)部署 Istio。

    `istio-demo.yaml` 或者 `istio-demo-auth.yaml` 模板中都包含了跟踪支持，或者还可以使用 Helm chart 的方式进行部署，需要设置 `--set tracing.enabled=true` 选项。

* 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 样例应用。

## 访问 Dashboard

用端口转发的方式启用对 Jaeger dashboard 的访问：

{{< text bash >}}
$ kubectl port-forward -n istio-system $(kubectl get pod -n istio-system -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 16686:16686 &
{{< /text >}}

打开浏览器访问 [http://localhost:16686](http://localhost:16686) 来访问 Jaeger 的 Dashboard。

## 使用 Bookinfo 例子生成跟踪数据

在 Bookinfo 应用启动运行之后，访问 `http://$GATEWAY_URL/productpage` 一次或者多次之后，会生成跟踪数据。

在 Jaeger dashboard 左侧版面中，从 Service 下拉列表中选择 `productpage`，点击 `Find Traces` 按钮，就会看到类似下图的内容：

{{< image width="100%" ratio="42.35%"
    link="/docs/tasks/telemetry/distributed-tracing/jaeger/istio-tracing-list.png"
    caption="跟踪 Dashboard"
    >}}

如果点击顶部（`most recent`）的跟踪信息，会看到最后一次刷新 `/productpage` 页面的信息。显示的内容会跟下图类似：

{{< image width="100%" ratio="42.35%"
    link="/docs/tasks/telemetry/distributed-tracing/jaeger/istio-tracing-details.png"
    caption="跟踪信息详细视图"
    >}}

正如你所见，跟踪信息是由一系列的 Span 组成的，每个 Span 对应着 `/productpage` 请求过程中 Bookinfo 服务的调用。目标服务（右侧）的标签标识了每一行的耗时。

第一行代表了外部调用到 `productpage` 服务的过程。`istio-ingressgateway` 是外部请求的入口。从图中我们可以看到，整个请求花费了大概 40 毫秒。在执行过程中，`productpage` 调用了 `details` 服务，消耗了约 4 毫秒；接下来调用了 `reviews` 服务。`reviews` 服务消耗的了大概 27 毫秒。其中还包含了 `reviews` 对 `ratings` 服务所占用的 7 毫秒。

## 发生了什么？

虽然 Istio 代理能够自动发送 Span 信息，但还是需要一些辅助手段来把整个跟踪过程统一起来。应用程序应该自行传播跟踪相关的 HTTP Header，这样在代理发送 Span 信息的时候，才能正确的把同一个跟踪过程统一起来。

为了完成跟踪的传播过程，应用应该从请求源头中收集下列的 HTTP Header，并传播给外发请求：

* `x-request-id`
* `x-b3-traceid`
* `x-b3-spanid`
* `x-b3-parentspanid`
* `x-b3-sampled`
* `x-b3-flags`
* `x-ot-span-context`

如果观察一下示例应用的代码，会看到 `productpage` 应用（Python）从 HTTP 请求中获取需要的 HTTP Header：

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

`reviews` 应用（Java）也做了类似的事情：

{{< text jzvz >}}
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

在对下游服务进行调用的时候，就应该在请求中包含上面代码中获取到的 HTTP Header。

## 跟踪采样

Istio 默认捕获所有请求的跟踪。例如，何时每次访问时都使用上面的 Bookinfo 示例应用程序
`/ productpage`你在 Jaeger 看到了相应的痕迹仪表板。此采样率适用于测试或低流量目。
对于高流量网格，您可以降低跟踪采样以下两种方式之一的百分比：

* 在网格设置期间，使用 Helm 选项 `pilot.traceSampling` 来设置跟踪采样的百分比。
有关设置选项的详细信息，请参阅 [Helm 安装](/zh/docs/setup/kubernetes/helm-install/)文档。
* 在运行的网格中，编辑 `istio-pilot` 部署并使用以下步骤更改环境变量：

    1. 要在加载了部署配置文件的情况下打开文本编辑器，请运行以下命令：

        {{< text bash >}}
        $ kubectl -n istio-system edit deploy istio-pilot
        {{< /text >}}

    1. 找到 `PILOT_TRACE_SAMPLING` 环境变量，并将 `value：` 更改为您想要的百分比。

在这两种情况下，有效值都是0.0到100.0，精度为0.01。

## 清理

* 如果不准备继续尝试后续任务，可参照 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理)的介绍关停应用。

---
title: LightStep
description: 怎样配置代理才能把追踪请求发送到 LightStep。
weight: 11
keywords: [telemetry,tracing,lightstep]
aliases:
 - /zh/docs/tasks/telemetry/distributed-tracing/lightstep/
---

此任务介绍如何配置 Istio 才能收集追踪 span ，并且把收集到的 span 发送到 [LightStep Tracing](https://lightstep.com/products/) 或 [LightStep [𝑥]PM](https://lightstep.com/products/)。
LightStep 可以分析来自大规模生产级软件的 100% 未采样的事务数据，并做出容易理解的的分布式追踪和指标信息，这有助于解释性能行为和并加速根因分析。
在此任务的结尾，Istio 将追踪 span 从代理发送到 LightStep Satellite 池，以让它们在 web UI 上展示。

此任务使用 [Bookinfo](/zh/docs/examples/bookinfo/) 的样例代码作为示例。

## 开始之前{#before-you-begin}

1. 确保你有一个 LightStep 账户。这里可以免费[注册](https://lightstep.com/products/tracing/)试用 LightStep Tracing，或者[联系 LightStep](https://lightstep.com/contact/) 创建企业级的 LightStep [𝑥]PM 账户。

1. 对于 [𝑥]PM 用户，确保你已有 satellite 池并且配置了 TLS 证书和一个暴露出来的安全 GRPC 端口。这里[配置 LightStep Satellite](https://docs.lightstep.com/docs/install-and-configure-satellites) 有配置 satellite 的详细说明。

   对于 LightStep Tracing 的用户，你的 satellites 是已经配置好的。

1. 确保你有 LightStep 的[访问令牌](https://docs.lightstep.com/docs/create-and-manage-access-tokens)。

1. 需要使用你的 satellite 地址来部署 Istio。
    对于 [𝑥]PM 用户，确保你可以使用 `<Host>:<Port>` 格式的地址访问 satellite 池，例如 `lightstep-satellite.lightstep:9292`。

    对于 LightStep Tracing 的用户，使用这个地址 `collector-grpc.lightstep.com:443`。

1. 使用以下指定的配置参数部署 Istio：
    - `pilot.traceSampling=100`
    - `global.proxy.tracer="lightstep"`
    - `global.tracer.lightstep.address="<satellite-address>"`
    - `global.tracer.lightstep.accessToken="<access-token>"`
    - `global.tracer.lightstep.secure=true`
    - `global.tracer.lightstep.cacertPath="/etc/lightstep/cacert.pem"`

    当执行安装命令时，可以使用 `--set key=value` 语法来配置这些参数，例如：

    {{< text bash >}}
    $ istioctl manifest apply \
        --set values.pilot.traceSampling=100 \
        --set values.global.proxy.tracer="lightstep" \
        --set values.global.tracer.lightstep.address="<satellite-address>" \
        --set values.global.tracer.lightstep.accessToken="<access-token>" \
        --set values.global.tracer.lightstep.secure=true \
        --set values.global.tracer.lightstep.cacertPath="/etc/lightstep/cacert.pem"
    {{< /text >}}

1. 把 satellite 池证书颁发机构发的证书作为一个密钥存储在默认的命名空间下。
    对于 LightStep Tracing 用户，要在这里下载并使用[这个证书](https://docs.lightstep.com/docs/instrument-with-istio-as-your-service-mesh)。
    如果你把 Bookinfo 应用程序部署在了其它的命名空间下，就要在对的应命名空间下创建相应的密钥证书。

    {{< text bash >}}
    $ CACERT=$(cat Cert_Auth.crt | base64) # Cert_Auth.crt contains the necessary CACert
    $ NAMESPACE=default
    {{< /text >}}

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
      apiVersion: v1
      kind: Secret
      metadata:
        name: lightstep.cacert
        namespace: $NAMESPACE
        labels:
          app: lightstep
      type: Opaque
      data:
        cacert.pem: $CACERT
    EOF
    {{< /text >}}

1. 按照[部署 Bookinfo 示例应用程序说明](/zh/docs/examples/bookinfo/#deploying-the-application)操作。

## 可视化追踪数据{#visualize-trace-data}

1. 按照[为 Bookinfo 应用程序创建 ingress 网关说明](/zh/docs/examples/bookinfo/#determine-the-ingress-IP-and-port)操作。

1. 为了验证上一步是否成功，请确认你在 shell 的环境变量中中设置了 `GATEWAY_URL` 。

1. 发送流量到示例应用程序。

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1. 打开 LightStep [web UI](https://app.lightstep.com/)。

1. 导航到 Explorer 。

1. 在顶部找到查询栏，在这里你可以用 **Service** 、**Operation** 和 **Tag** 的值进行过滤查询。

1. 从 **Service** 下拉列表中选择 `productpage.default`。

1. 点击 **Run** 。可以看到如下类似的内容：

    {{< image link="./istio-tracing-list-lightstep.png" caption="Explorer" >}}

1. 在延迟直方图下面点击示例追踪表格的第一行，就可以查看 `/productpage` 刷新后的详细信息。该页面类似下面：

    {{< image link="./istio-tracing-details-lightstep.png" caption="Detailed Trace View" >}}

这个截图显示了该追踪是由一组 span 组成。每一个 span 对应着在执行 `/productpage` 请求期间调用的一个 Bookinfo 服务。

追踪中的两个 spans 表示一个 RPC 请求。例如，从 `productpage` 到 `reviews` 的请求调用，以操作标签 `reviews.default.svc.cluster.local:9080/*` 和服务标签 `productpage.default: proxy client` 的 span 开始。该服务表示是这个调用的客户端 span。截图显示此次调用耗时 15.30 毫秒。第二个 span 标记有操作标签 `reviews.default.svc.cluster.local:9080/*` 操作和服务标签 `reviews.default: proxy server` 。第二个 span 是第一个 span 的下一级，表示调用的服务端 span。截图显示此次调用耗时 14.60 毫秒。

{{< warning >}}
集成后的 LightStep 当前无法捕获由 Istio 的内部操作组件（如 Mixer）生成的 span。
{{< /warning >}}

## 追踪采样{#trace-sampling}

Istio 通过配置追踪采样百分比来捕获追踪信息。想了解如何修改追踪采样百分比，请访问[分布式追踪追踪采样部分](../overview/#trace-sampling)。
使用 LightStep 时，我们不建议将追踪采样的百分比降低到 100% 以下。要处理高流量的网格，请考虑扩大您的 satellite 池的大小。

## 清除{#cleanup}

如果你不想继续执测试操作任务，可以从集群中删除 Bookinfo 示例应用程序和所有的 LightStep 密钥。

1. 删除 Bookinfo 应用程序，请参阅[清除 Bookinfo](/zh/docs/examples/bookinfo/#cleanup) 说明。

1. 删除给 LightStep 生成的密钥：

{{< text bash >}}
$ kubectl delete secret lightstep.cacert
{{< /text >}}

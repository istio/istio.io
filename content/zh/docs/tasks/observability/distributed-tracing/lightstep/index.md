---
title: LightStep
description: 如何配置代理以将跟踪请求发送到 LightStep。
weight: 11
keywords: [telemetry,tracing,lightstep]
aliases:
 - /zh/docs/tasks/telemetry/distributed-tracing/lightstep/
---

此任务向您展示如何配置 Istio 以收集 trace spans 并将其发送到 [LightStep Tracing](https://lightstep.com/products/) 或 [LightStep [𝑥]PM](https://lightstep.com/products/)。
LightStep 使您可以分析来自大规模生产级软件的 100% 未采样的事务数据，以产生有意义的分布式跟踪和指标，其有助于解释性能行为并加速根因分析。
在此任务的结尾，Istio 将 trace spans 从代理发送到 LightStep Satellite 池，以使它们可以从 web UI 获取。

此任务使用 [Bookinfo](/zh/docs/examples/bookinfo/) 样例代码作为示例。

## 开始之前{#before-you-begin}

1. 确保您有 LightStep 账户。[注册](https://lightstep.com/products/tracing/)以便免费试用 LightStep Tracing，或者[联系 LightStep](https://lightstep.com/contact/) 创建企业级 LightStep [𝑥]PM 账户。

1. 对于 [𝑥]PM 用户，确保您已为 satellite 池配置了 TLS 证书和一个安全的 GRPC 端口。
   参考[配置 LightStep Satellite](https://docs.lightstep.com/docs/satellite-setup) 来获取有关配置 satellite 的详细信息。

   对于 LightStep Tracing 的用户，您的 satellites 已经配置完毕。

1.  确保您有 LightStep 的[访问令牌](https://docs.lightstep.com/docs/project-access-tokens)。

1.  您需要使用您的 satellite 地址来部署 Istio。
    对于 [𝑥]PM 用户，确保您可以使用 `<Host>:<Port>` 格式的地址访问 satellite 池，例如 `lightstep-satellite.lightstep:9292`。

    对于 LightStep Tracing 的用户，使用地址 `collector-grpc.lightstep.com:443`。

1.  使用以下指定的配置参数部署 Istio：
    - `pilot.traceSampling=100`
    - `global.proxy.tracer="lightstep"`
    - `global.tracer.lightstep.address="<satellite-address>"`
    - `global.tracer.lightstep.accessToken="<access-token>"`
    - `global.tracer.lightstep.secure=true`
    - `global.tracer.lightstep.cacertPath="/etc/lightstep/cacert.pem"`

    当您执行安装命令时，您可以使用 `--set key=value` 语法来配置这些参数，例如：

    {{< text bash >}}
    $ istioctl manifest apply \
        --set values.pilot.traceSampling=100 \
        --set values.global.proxy.tracer="lightstep" \
        --set values.global.tracer.lightstep.address="<satellite-address>" \
        --set values.global.tracer.lightstep.accessToken="<access-token>" \
        --set values.global.tracer.lightstep.secure=true \
        --set values.global.tracer.lightstep.cacertPath="/etc/lightstep/cacert.pem"
    {{< /text >}}

1.  在 default namespace 下，存储您的 satellite 池的证书颁发机构证书作为一个 secret。
    对于 LightStep Tracing 用户，下载并使用[这个证书](https://docs.lightstep.com/docs/use-istio-as-your-service-mesh-with-lightstep)。
    如果您在其他的 namespace 下部署 Bookinfo 应用程序，请改为在对应 namespace 下创建 secret。

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

1.   遵循[部署 Bookinfo 示例应用程序指南](/zh/docs/examples/bookinfo/#deploying-the-application)。

## 可视化跟踪数据{#visualize-trace-data}

1.  遵循[为 Bookinfo 应用程序创建 ingress 网关指南](/zh/docs/examples/bookinfo/#determine-the-ingress-ip-and-port)。

1.  为了验证上一步是否成功，请确认您在 shell 中设置了 `GATEWAY_URL` 环境变量。

1.  发送流量到示例应用程序。

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  加载 LightStep [web UI](https://app.lightstep.com/)。

1.  导航到 Explorer。

1.  在顶部找到查询栏。使用查询栏，您可以通过 **Service**、**Operation**、**Tag** 的值交互式地过滤结果。

1.  从 **Service** 下拉列表中选择 `productpage.default`。

1.  点击 **Run**。您可以看到如下类似的内容：

    {{< image link="./istio-tracing-list-lightstep.png" caption="Explorer" >}}

1.  点击延迟直方图下方的示例 traces 表格的第一行以查看刷新 `/productpage` 所对应的详细信息。该页面看起来类似于：

    {{< image link="./istio-tracing-details-lightstep.png" caption="Detailed Trace View" >}}

屏幕截图显示了该跟踪由一组 span 组成。每一个 span 对应 `/productpage` 请求执行中调用的 Bookinfo 服务。

Trace 中的两个 spans 代表每次 RPC。
例如，从 `productpage` 到 `reviews` 的调用，以标记有 `reviews.default.svc.cluster.local:9080/*` operation 和 `productpage.default: proxy client` service 的 span 开始。
该服务代表调用客户端的 span。
屏幕截图显示此次调用耗时 15.30 毫秒。
第二个 span 标记有`reviews.default.svc.cluster.local:9080/*` 操作和 `reviews.default: proxy server` 服务。
第二个 span 是第一个 span 的子级，代表调用的服务端的 span。
屏幕截图显示此次调用耗时 14.60 毫秒。

{{< warning >}}
LightStep 集成在当前无法捕获由 Istio 的内部操作组件（如 Mixer ）生成的 span。
{{< /warning >}}

## 跟踪采样{#trace-sampling}

Istio 以可配置的跟踪采样百分比来捕获 trace。
要了解如何修改跟踪采样百分比，请访问[分布式跟踪跟踪采样部分](../overview/#trace-sampling)。

使用 LightStep 时，我们不建议将跟踪采样的百分比降低到 100% 以下。
要处理高流量的网格，请考虑扩大您的 satellite 池的大小。

## 清除{#cleanup}

如果您不计划任何后续任务，可以从您的集群中删除 Bookinfo 示例应用程序和所有的 LightStep secrets。

1. 要删除 Bookinfo 应用程序，请参阅[清除 Bookinfo](/zh/docs/examples/bookinfo/#cleanup) 说明。

1. 删除 LightStep 生成的 secret：

{{< text bash >}}
$ kubectl delete secret lightstep.cacert
{{< /text >}}

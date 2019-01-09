---
title: 使用 LightStep [𝑥]PM 进行分布式追踪
description: 如何配置代理以发送请求至 LightStep [𝑥]PM.
weight: 11
keywords: [telemetry,tracing,lightstep]
---

此任务说明如何配置 Istio 以收集追踪 span 并将其发送到 LightStep [𝑥]PM。
[𝑥]PM 让您可以从大规模生产软件中分析 100％ 未抽样的事务数据，从而产生有意义的分布式跟踪信息和 metrics，用于帮助解释性能行为并加快根本原因分析。
更多信息请访问 [LightStep 网站](https://lightstep.com)。
在此任务的最后，Istio 将从代理发送 span 到一个 LightStep [𝑥]PM Satellite pool，使得它们在 web 界面上可用。

## 开始之前

1. 请确保您拥有一个 LightStep 账号。[请联系 LightStep](https://lightstep.com/contact/) 创建账号。

1. 请确保您具有配置了 TLS 证书的 satellite pool 和已公开的安全 GRPC 端口。关于如何设置 satellites 请查看 [LightStep Satellite 配置](https://docs.lightstep.com/docs/satellite-setup)。

1. 请确保您具有一个 LightStep 访问令牌。

1. 请确保您可以使用 `<Host>:<Port>` 的地址形式访问 satellite pool，例如 `lightstep-satellite.lightstep:9292`。

1. 指定如下配置参数部署 Istio：
    - `global.proxy.tracer="lightstep"`
    - `global.tracer.lightstep.address="<satellite-address>"`
    - `global.tracer.lightstep.accessToken="<access-token>"`
    - `global.tracer.lightstep.secure=true`
    - `global.tracer.lightstep.cacertPath="/etc/lightstep/cacert.pem"`

    如果通过 `helm template` 进行安装，您可以在运行 `helm` 命令时，使用 `--set key=value` 的格式设置这些参数。例如：

    {{< text bash >}}
    $ helm template \
        --set global.proxy.tracer="lightstep" \
        --set global.tracer.lightstep.address="<satellite-address>" \
        --set global.tracer.lightstep.accessToken="<access-token>" \
        --set global.tracer.lightstep.secure=true \
        --set global.tracer.lightstep.cacertPath="/etc/lightstep/cacert.pem" \
        install/kubernetes/helm/istio \
        --name istio --namespace istio-system > $HOME/istio.yaml
    $ kubectl create namespace istio-system
    $ kubectl apply -f $HOME/istio.yaml
    {{< /text >}}

1. 将您的 satellite pool 的 CA 证书以 secret 形式保存在 default namespace 中。
   如果您在不同的 namespace 中部署 Bookinfo 应用，请在该 namespace 中创建这个 secret。

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

1. 遵循[部署 Bookinfo 示例应用程序说明](/zh/docs/examples/bookinfo/#部署应用)。

## 可视化追踪数据

1. 遵循[为 Bookinfo 应用创建 ingress gateway 的说明](/zh/docs/examples/bookinfo/#确定-ingress-的-ip-和端口)。

1. 为了验证前序步骤是否成功，请确保在 shell 中设置了 `GATEWAY_URL` 环境变量。

1. 发送流量到示例应用程序。

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1. 加载 LightStep [𝑥]PM [web UI](https://app.lightstep.com/)。

1. 浏览该界面。

1. 在页面顶部找到查询栏。查询栏允许你通过 **Service**、**Operation** 和 **Tag** 值交互式的筛选结果。

1. 从 **Service** 下拉列表中选择 `productpage.default`。

1. 点击 **Run**。您将看到一些和下面相似的东西：

    {{< image link="/docs/tasks/telemetry/distributed-tracing/lightstep/istio-tracing-list-lightstep.png" caption="Explorer" >}}

1. 单击延迟直方图下方的示例跟踪表中的第一行，以查看与刷新 `/productpage` 时相对应的详细信息。页面看起来像这样：

    {{< image link="/docs/tasks/telemetry/distributed-tracing/lightstep/istio-tracing-details-lightstep.png" caption="Detailed Trace View" >}}

屏幕截图显示跟踪由一组 span 组成。 每个 span 对应于执行 `/productpage` 时调用的 Bookinfo 服务。

追踪中的两个 span 代表了每个 RPC。例如，从 `productpage` 到 `reviews` 的请求带有的 span 使用  `reviews.default.svc.cluster.local:9080/*` operation 和 `productpage.default: proxy client` 进行标记。这个
service 代表了客户端请求的 span。屏幕截图显示请求耗时 15.30 毫秒。第二个 span 使用 `reviews.default.svc.cluster.local:9080/*` operation 和 `reviews.default: proxy server` service 进行标记。第二个 span 是第一个的子级，代表了服务端请求的 span。屏幕截图显示请求耗时 14.60 毫秒。

> {{< warning_icon >}} LightStep 集成目前不能捕获 Istio 内部组件（如 Mixer）产生的 span。

## 追踪采样

Istio 以可配置的追踪采样百分比捕获追踪数据。要了解如何修改追踪采样百分比，请访问[使用 Jaeger 追踪采样进行分布式追踪小节](../overview/#trace-sampling)。
当使用 LightStep [𝑥]PM 时，我们不推荐将追踪采样百分比降低到 100% 以下。要处理高流量网格，请考虑对您的 satellite pool 进行扩容。

## 清理

如果您没有计划任何后续任务，请从集群中删除 Bookinfo 示例应用程序及任何 LightStep [𝑥]PM secret。

1. 要删除 Bookinfo 应用程序，请参考 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理")说明。

1. 删除为 LightStep [𝑥]PM 生成的 secret。

{{< text bash >}}
$ kubectl delete secret lightstep.cacert
{{< /text >}}

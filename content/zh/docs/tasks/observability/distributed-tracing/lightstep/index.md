---
title: Lightstep
description: 怎样配置代理才能把追踪请求发送到 Lightstep。
weight: 11
keywords: [telemetry, tracing, lightstep]
aliases:
  - /zh/docs/tasks/telemetry/distributed-tracing/lightstep/
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

{{< boilerplate telemetry-tracing-tips >}}

此任务介绍如何配置 Istio 才能收集追踪 span，并且把收集到的 span 发送到
[Lightstep](https://lightstep.com/products/)。Lightstep 可以分析来自大规模生产级软件的
100% 未采样的事务数据，并做出容易理解的的分布式追踪和指标信息，这有助于解释性能行为和并加速根因分析。
在此任务的结尾，Istio 将追踪 span 从代理发送到 Lightstep Satellite 池，
以让它们在 web UI 上展示。默认情况下，所有的 HTTP 请求都被捕获（为了看到端到端的追踪，
你的代码需要转发 OT 头，即使它没有参与到追踪）。

如果您只想直接从 Istio 收集追踪 span（而不是直接向您的代码添加特定的检测），那么您不需要配置任何追踪器，
只要您的服务转发[追踪器产生的 HTTP 请求头](https://www.envoyproxy.io/docs/envoy/latest/configuration/http_conn_man/headers#config-http-conn-man-headers-x-ot-span-context)。

此任务使用 [Bookinfo](/zh/docs/examples/bookinfo/) 的样例代码作为示例。

## 开始之前{#before-you-begin}

1. 确保你有一个 Lightstep 账户。这里可以免费[注册](https://lightstep.com/products/tracing/)试用 Lightstep。

1. 如果您使用的是[本地 Satellite](https://docs.lightstep.com/docs/learn-about-satellites#on-premise-satellites)，
    请确保您有一个配置了 TLS 证书的 Satellite 池和一个公开的安全 GRPC 端口。
    请参阅[安装和配置 Satellite](https://docs.lightstep.com/docs/install-and-configure-satellites)
    获取更多有关设置 Satellite 的细节。

    对于 [Lightstep 公共 Satellite](https://docs.lightstep.com/docs/learn-about-satellites#public-satellites)
    或[开发者模式 Satellite](https://docs.lightstep.com/docs/learn-about -satellites#developer-satellites)，
    您的 Satellite 已经配置好了。但是，您需要将[此证书](https://docs.lightstep.com/docs/instrument-with-istio-as-your-service-mesh#cacertpem-file)下载到本地目录。

1. 确保您有 Lightstep 的[访问令牌](https://docs.lightstep.com/docs/create-and-manage-access-tokens)。
    访问令牌允许您的应用程序与您的 Lightstep 项目进行通信。

## 部署 Istio{#deploy-istio}

如何部署 Istio 取决于您使用的 Satellite 类型。

### 使用本地 Satellite 部署 Istio{#deploy-istio-with-on-premise- satellites}

这些说明不假定使用 TLS。如果您为 Satellite 池使用 TLS，
请遵循[公共 Satellite 池](#deploy-istio-with-public-or-developer-mode-satellites)的配置，
但使用您自己的证书和您自己的池的端点（`host:port`）。

1. 您需要用 Satellite 地址部署 Istio，地址格式为`<主机>：<端口>`，例如 `lightstep-satellite.lightstep:9292`。
    可以在您的[配置](https://docs.lightstep.com/docs/satellite-configuration-parameters#ports)文件中找到这个地址。

1. 使用以下指定的配置参数部署 Istio：

    - `global.proxy.tracer="lightstep"`
    - `meshConfig.defaultConfig.tracing.sampling=100`
    - `meshConfig.defaultConfig.tracing.lightstep.address="<satellite-address>"`
    - `meshConfig.defaultConfig.tracing.lightstep.accessToken="<access-token>"`

    当执行安装命令时，可以使用 `--set key=value` 语法来配置这些参数，例如：

    {{< text bash >}}
    $ istioctl install \
        --set global.proxy.tracer="lightstep" \
        --set meshConfig.defaultConfig.tracing.sampling=100 \
        --set meshConfig.defaultConfig.tracing.lightstep.address="<satellite-address>" \
        --set meshConfig.defaultConfig.tracing.lightstep.accessToken="<access-token>" \
    {{< /text >}}

### 使用公共或开发者模式 Satellite 部署 Istio{#deploy-istio-with-public-or-developer-mode-satellites}

如果您使用的是公共或开发者模式 Satellite，或者如果您使用的是带有 TLS 证书的本地 Satellite，请按照这些步骤操作。

1. 把 Satellite 池证书颁发机构发的证书作为一个密钥存储在默认的命名空间下。
    对于 Lightstep Tracing 用户，要在这里下载并使用[这个证书](https://docs.lightstep.com/docs/instrument-with-istio-as-your-service-mesh)。
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

1. 使用以下指定的配置参数部署 Istio：

    {{< text yaml >}}
    global:
      proxy:
        tracer: "lightstep"
    meshConfig:
      defaultConfig:
        tracing:
          lightstep:
            address: "ingest.lightstep.com:443"
            accessToken: "<access-token>"
          sampling: 100
          tlsSettings
            mode: "SIMPLE"
            # Specifying ca certificate here will moute `lightstep.cacert` secret volume
            # at all sidecars by default.
            caCertificates="/etc/lightstep/cacert.pem"
    components:
      ingressGateways:
      # `lightstep.cacert` secret volume needs to be mount at gateways via k8s overlay.
      - name: istio-ingressgateway
        enabled: true
        k8s:
          overlays:
          - kind: Deployment
            name: istio-ingressgateway
            patches:
            - path: spec.template.spec.containers[0].volumeMounts[-1]
              value: |
                name: lightstep-certs
                mountPath: /etc/lightstep
                readOnly: true
            - path: spec.template.spec.volumes[-1]
              value: |
                name: lightstep-certs
                secret:
                  secretName: lightstep.cacert
                  optional: true
    {{< /text >}}

## 安装并运行 Bookinfo 应用程序{#install-and-run-the-bookinfo-app}

1. 按照[部署 Bookinfo 示例应用程序的说明](/zh/docs/examples/bookinfo/#deploying-the-application).

1. 按照[为 Bookinfo 应用程序创建 Ingress 网关说明](/zh/docs/examples/bookinfo/#determine-the-ingress-ip-and-port)操作。

1. 为了验证上一步是否成功，请确认你在 shell 的环境变量中中设置了 `GATEWAY_URL`。

1. 发送流量到示例应用程序。

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

## 可视化追踪数据{#visualize-trace-data}

1. 打开 Lightstep [web UI](https://app.lightstep.com/)。您会在服务目录中看到三个 Bookinfo 服务。

    {{< image link="./istio-services.png" caption="Bookfinder services in the Service Directory" >}}

1. 导航到 Explorer 视图。

    {{< image link="./istio-explorer.png" caption="Explorer view" >}}

1. 在顶部找到查询栏，在这里你可以用 **Service** 、**Operation** 和 **Tag** 的值进行过滤查询。

1. 从 **Service** 下拉列表中选择 `productpage.default`。

1. 点击 **Run** 。可以看到如下类似的内容：

    {{< image link="./istio-tracing-list-lightstep.png" caption="Explorer" >}}

1. 在延迟直方图下面点击示例追踪表格的第一行，就可以查看 `/productpage` 刷新后的详细信息。该页面类似下面：

    {{< image link="./istio-tracing-details-lightstep.png" caption="Detailed Trace View" >}}

这个截图显示了该追踪是由一组 span 组成。每一个 span 对应着在执行 `/productpage` 请求期间调用的一个 Bookinfo 服务。

追踪中的两个 span 表示一个 RPC 请求。例如从 `productpage` 到 `reviews` 的请求调用，
以操作标签 `reviews.default.svc.cluster.local:9080/*` 和服务标签
`productpage.default: proxy client` 的 span 开始。该服务表示是这个调用的客户端 span。
截图显示此次调用耗时 15.30 毫秒。第二个 span 标记有操作标签 `reviews.default.svc.cluster.local:9080/*`
操作和服务标签 `reviews.default: proxy server`。第二个 span 是第一个 span 的下一级，
表示调用的服务端 span。截图显示此次调用耗时 14.60 毫秒。

## 追踪采样{#trace-sampling}

Istio 通过配置追踪采样百分比来捕获追踪信息。想了解如何修改追踪采样百分比，
请访问[分布式追踪采样部分](/zh/docs/tasks/observability/distributed-tracing/mesh-and-proxy-config/#customizing-trace-sampling)。
使用 Lightstep 时，我们不建议将追踪采样的百分比降低到 100% 以下。要处理高流量的网格，请考虑扩大您的 Satellite 池的大小。

## 清除{#cleanup}

如果你不想继续执测试操作任务，可以从集群中删除 Bookinfo 示例应用程序和所有的 Lightstep 密钥。

1. 删除 Bookinfo 应用程序，请参阅[清除 Bookinfo](/zh/docs/examples/bookinfo/#cleanup) 说明。

1. 删除给 Lightstep 生成的密钥：

{{< text bash >}}
$ kubectl delete secret lightstep.cacert
{{< /text >}}

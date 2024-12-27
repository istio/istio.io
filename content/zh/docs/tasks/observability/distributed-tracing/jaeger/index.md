---
title: Jaeger
description: 了解如何配置代理以向 Jaeger 发送追踪请求。
weight: 6
keywords: [telemetry,tracing,jaeger,span,port-forwarding]
aliases:
 - /zh/docs/tasks/telemetry/distributed-tracing/jaeger/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

完成此任务后，您将了解如何让您的应用程序参与 [Jaeger](https://www.jaegertracing.io/)
的追踪，无论您用什么语言、框架或平台来构建应用程序。

此任务使用 [Bookinfo](/zh/docs/examples/bookinfo/) 作为演示的应用程序。

要了解 Istio 如何处理追踪，请查看这个任务的[概述](../overview/)。

## 开始之前 {#before-you-begin}

1. 根据 [Jaeger 安装](/zh/docs/ops/integrations/jaeger/#installation )文档将
   Jaeger 安装到您的集群中。

1. 部署 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application) 示例应用程序。

## 配置 Istio 进行分布式链路追踪 {#configure-istio-for-distributed-tracing}

### 配置扩展提供程序 {#configure-an-extension-provider}

使用引用 Jaeger 收集器服务的[扩展提供程序](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider)安装 Istio：

{{< text bash >}}
$ cat <<EOF > ./tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing: {} # 禁用旧版 MeshConfig 链路追踪选项
    extensionProviders:
    - name: jaeger
      opentelemetry:
        port: 4317
        service: jaeger-collector.istio-system.svc.cluster.local
EOF
$ istioctl install -f ./tracing.yaml --skip-confirmation
{{< /text >}}

### 开启链路追踪 {#enable-tracing}

通过应用以下配置启用链路追踪：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: jaeger
EOF
{{< /text >}}

## 访问仪表盘 {#accessing-the-dashboard}

[远程访问遥测插件任务](/zh/docs/tasks/observability/gateways)详细说明了如何通过网关配置对 Istio 插件的访问。

对于测试（或临时访问），您也可以使用端口转发。假设已将 Jaeger 部署到 `istio-system`
命名空间，请使用以下内容：

{{< text bash >}}
$ istioctl dashboard jaeger
{{< /text >}}

## 使用 Bookinfo 示例产生追踪{#generating-traces-using-the-Bookinfo-sample}

1. 当 Bookinfo 应用程序启动并运行时，访问 `http://$GATEWAY_URL/productpage`
   一次或多次以生成追踪信息。

    {{< boilerplate trace-generation >}}

1. 从仪表盘左边面板的 **Service** 下拉列表中选择 `productpage.default` 并点击
    **Find Traces**：

    {{< image link="./istio-tracing-list.png" caption="Tracing Dashboard" >}}

1. 点击位于最上面的最近一次追踪，查看对应最近一次访问 `/productpage` 的详细信息：

    {{< image link="./istio-tracing-details.png" caption="Detailed Trace View" >}}

1. 追踪信息由一组 Span 组成，每个 Span 对应一个 Bookinfo Service。这些 Service
   在执行 `/productpage` 请求时被调用，或是 Istio 内部组件，例如：`istio-ingressgateway`。

## 清理{#cleanup}

1. 使用 Control C 或删除任何可能仍在运行的 `istioctl` 进程：

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

1. 如果您没有计划探索任何接下来的任务，请参考 [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup)中的说明，
   关闭整个应用程序。

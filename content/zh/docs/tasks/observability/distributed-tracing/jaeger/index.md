---
title: Jaeger
description: 了解如何配置代理以向 Jaeger 发送追踪请求。
weight: 10
keywords: [telemetry,tracing,jaeger,span,port-forwarding]
aliases:
 - /zh/docs/tasks/telemetry/distributed-tracing/jaeger/
---

完成此任务后，您将了解如何让您的应用程序参与 [Jaeger](https://www.jaegertracing.io/)的追踪，
而不管您用来构建应用程序的语言、框架或平台是什么。

此任务使用 [Bookinfo](/zh/docs/examples/bookinfo/) 作为演示的应用程序。

要了解 Istio 如何处理追踪，请查看这个任务的[概述](../overview/)。

## 开始之前{#before-you-begin}

1. 要设置 Istio，按照[安装指南](/zh/docs/setup/install/istioctl)中的说明进行操作。

    a) 通过设置 `--set values.tracing.enabled = true` 安装选项以启用 tracing 的“开箱即用”的演示/测试环境

    b) 通过使用现有 Jaeger 实例（例如使用 [operator](https://github.com/jaegertracing/jaeger-operator)进行创建，然后设置`--set values.global.tracer.zipkin.address = <jaeger-collector-service>.<jaeger -collector-namespace>:9411` 的安装选项。

    {{< warning >}}
    启用跟踪时，可以设置 Istio 用于跟踪的采样率。
    使用这个 `values.pilot.traceSampling` 选项设置采样率。默认的采样率为 1%.
    {{< /warning >}}

1. 部署 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application) 示例应用程序。

## 访问仪表盘{#accessing-the-dashboard}

[远程访问遥测插件](/zh/docs/tasks/observability/gateways)详细介绍了如何通过网关配置对 Istio 插件的访问。或者，如果要使用 Kubernetes ingress，请在安装过程中指定选项 `--set values.tracing.ingress.enabled = true`。

对于测试（或临时访问），您也可以使用端口转发。假设已将 Jaeger 部署到 “istio-system” 命名空间，请使用以下内容：

{{< text bash >}}
$ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 15032:16686
{{< /text >}}

打开您的浏览器并访问 [http://localhost:15032](http://localhost:15032)。

## 使用 Bookinfo 示例产生追踪{#generating-traces-using-the-Bookinfo-sample}

1. 当 Bookinfo 应用程序启动并运行时，访问 `http://$GATEWAY_URL/productpage` 一次或多次以生成追踪信息。

1. 从仪表盘左边面板的 **Service** 下拉列表中选择 `productpage` 并点击 **Find Traces**：

    {{< image link="./istio-tracing-list.png" caption="追踪仪表盘" >}}

1. 点击位于最上面的最近一次追踪，查看对应最近一次访问 `/productpage` 的详细信息：

    {{< image link="./istio-tracing-details.png" caption="详细追踪视图" >}}

1. 追踪信息由一组 span 组成，每个 span 对应一个 Bookinfo service。这些 service 在执行 `/productpage` 请求时被调用，或是 Istio 内部组件，例如：`istio-ingressgateway`

## 清理{#cleanup}

1. 停止任何可能还在运行的 `kubectl port-forward` 进程：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

1. 如果您没有计划探索任何接下来的任务，请参考 [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup)中的说明，关闭整个应用程序。


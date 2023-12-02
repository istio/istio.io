---
title: Jaeger
description: 了解如何配置代理以向 Jaeger 发送追踪请求。
weight: 10
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

## 开始之前{#before-you-begin}

1. 根据 [Jaeger 安装](/zh/docs/ops/integrations/jaeger/#installation )文档将
   Jaeger 安装到您的集群中。

1. 启用追踪时，您可以设置 Istio 用于追踪的 Sampling Rate。
    安装时使用 `meshConfig.defaultConfig.tracing.sampling`
    [设置 Sampling Rate](/zh/docs/tasks/observability/distributed-tracing/configurability/#customizing-trace-sampling)。
    默认的 Sampling Rate 为 1%。

1. 部署 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application) 示例应用程序。

## 访问仪表盘{#accessing-the-dashboard}

[远程访问遥测插件](/zh/docs/tasks/observability/gateways)详细介绍了如何通过网关配置对
Istio 插件的访问。

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

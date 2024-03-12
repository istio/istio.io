---
title: Zipkin
description: 了解如何通过配置代理以向 Zipkin 发送追踪请求。
weight: 10
keywords: [telemetry,tracing,zipkin,span,port-forwarding]
aliases:
    - /zh/docs/tasks/zipkin-tracing.html
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

通过本任务，您将了解如何使应用程序可被 [Zipkin](https://zipkin.io/) 追踪，
而无需考虑应用程序使用何种开发语言、框架或平台。

本任务使用 [Bookinfo](/zh/docs/examples/bookinfo/) 作为示例应用程序。

要了解 Istio 如何处理追踪，请访问此任务的[概述](../overview/)。

## 开始之前  {#before-you-begin}

1. 参考 [Zipkin 安装](/zh/docs/setup/install/istioctl)文档将 Zipkin 安装到您的集群中。

1. 启用追踪时，您可以设置 Istio 用于追踪的 Sampling Rate。
   安装时使用 `meshConfig.defaultConfig.tracing.sampling`
   [设置 Sampling Rate](/zh/docs/tasks/observability/distributed-tracing/configurability/#customizing-trace-sampling)，
   默认的 Sampling Rate 为 1%。

1. 部署 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application) 示例应用程序。

## 访问仪表盘  {#accessing-the-dashboard}

[远程访问遥测插件](/zh/docs/tasks/observability/gateways)详细介绍了如何通过网关配置对 Istio 插件的访问。

对于测试（或临时访问），您也可以使用端口转发。假设已将 Zipkin 部署到 `istio-system` 命名空间，请使用以下内容：

{{< text bash >}}
$ istioctl dashboard zipkin
{{< /text >}}

## 使用 Bookinfo 示例产生追踪  {#generating-traces-using-the-Bookinfo-sample}

1. 当 Bookinfo 应用程序启动并运行时，访问 `http://$GATEWAY_URL/productpage` 一次或多次以生成追踪信息。

    {{< boilerplate trace-generation >}}

1. 在搜索面板中，点击 `+` 号，从第一个下拉列表中选择 `serviceName`，
   从第二个下拉列表中选择 `productpage.default`，再点击搜索图标：

    {{< image link="./istio-tracing-list-zipkin.png" caption="Tracing Dashboard" >}}

1. 点击 `ISTIO-INGRESSGATEWAY` 的搜索结果，查看与之对应的最新的 `/productpage` 请求的详细信息：

    {{< image link="./istio-tracing-details-zipkin.png" caption="Detailed Trace View" >}}

1. 追踪由一组 Span 组成，其中每个 Span 对应一个 Bookinfo Service，这些服务在执行
   `/productpage` 请求或 Istio 内部组件时被调用，例如：`istio-ingressgateway`。

## 清理  {#cleanup}

1. 使用 Control-C 或删除任何可能仍在运行的 `istioctl` 进程：

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

1. 如果您不打算继续深入探索任何后续任务，请参考 [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup)说明，关闭应用程序。

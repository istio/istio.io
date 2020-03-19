---
title: Zipkin
description: 了解如何通过配置代理以将追踪请求发送到 Zipkin。
weight: 10
keywords: [telemetry,tracing,zipkin,span,port-forwarding]
aliases:
    - /zh/docs/tasks/zipkin-tracing.html
---

通过本任务，您将了解如何使应用程序可被 [Zipkin](https://zipkin.io/) 追踪，
而无需考虑应用程序使用何种开发语言、框架或平台。

本任务使用 [Bookinfo](/zh/docs/examples/bookinfo/) 作为示例应用程序。

要了解 Istio 如何处理追踪，请访问此任务的[概述](../overview/)。

## 开始之前{#before-you-begin}

1. 参考[安装指南](/zh/docs/setup/install/istioctl)中的说明，
    使用如下配置安装 Istio：

    a) 通过配置 `--set values.tracing.enabled=true` 和 `--set values.tracing.provider=zipkin` 选项可以安装一个“开箱即用”的演示或测试环境。

    b) 对于生产环境，通过配置 `--set values.global.tracer.zipkin.address=<zipkin-collector-service>.<zipkin-collector-namespace>:9411` 选项以使用已有的 Zipkin 实例。

    {{< warning >}}
    启用追踪时，可以通过 `Pilot.traceSampling` 选项设置 Istio 的追踪采样率。
    默认采样率为 1%。
    {{< /warning >}}

1. 部署 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application) 示例程序。

## 访问仪表盘{#accessing-the-dashboard}

[远程访问遥测组件](/zh/docs/tasks/observability/gateways)详细描述了如何通过配置网关以访问 Istio 组件。或者，如果要使用 Kubernetes ingress, 请在安装时配置 `--set values.tracing.ingress.enabled=true` 选项。

对于测试（和临时访问），您也可以使用端口转发。假设已将 Zipkin 部署到 `istio-system` 命名空间，请使用以下方法：

{{< text bash >}}
$ istioctl dashboard zipkin
{{< /text >}}

## 使用 Bookinfo 示例程序生成追踪报告{#generating-traces-using-the-Bookinfo-sample}

1. 当 Bookinfo 程序启动并正常运行后，访问 `http://$GATEWAY_URL/productpage` 一次或多次，
    以生成追踪信息。

    {{< boilerplate trace-generation >}}

1. 在顶部面板中，从 **Service Name** 下拉列表中选择感兴趣的服务（或“全部”），
    然后单击 **Find Traces**:

    {{< image link="./istio-tracing-list-zipkin.png" caption="Tracing Dashboard" >}}

1. 单击顶部的最新追踪，查看与之对应的最新 `/productpage` 请求的详细信息：

    {{< image link="./istio-tracing-details-zipkin.png" caption="Detailed Trace View" >}}

1. 追踪由一组 span 组成，
    其中每个 span 对应一个 Bookinfo 服务，该服务在执行 `/productpage` 请求或 Istio 内部组件时被调用，
    例如：`istio-ingressgateway`。

## 清理{#cleanup}

1. 删除所有可能仍在运行的 `istioctl` 进程，使用 control-C 或者：

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

1. 如果您不打算继续深入探索任何后续任务，请
    参考 [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup)说明
    关闭应用程序。


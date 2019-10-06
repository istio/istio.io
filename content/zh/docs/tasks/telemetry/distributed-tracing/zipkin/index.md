---
title: Zipkin
description: 了解如何配置代理以向 Zipkin 发送追踪请求。
weight: 10
keywords: [telemetry,tracing,zipkin,span,port-forwarding]
---

要了解 Istio 如何处理追踪，请查看这个任务的[概述](../overview/)。

## 开始之前

1. 按照[安装指南](/zh/docs/setup/)中的说明安装 Istio。

   使用 Helm chart 进行安装时，设置 `--set tracing.enabled=true` 选项以启用追踪，并通过 `--set tracing.provider=zipkin` 选项选择 `zipkin`
   作为追踪提供者。

1. 部署 [Bookinfo](/zh/docs/examples/bookinfo/#部署应用) 示例应用程序。

## 访问仪表盘

1. 要配置到追踪仪表盘的访问，请使用端口转发：

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=istio-ingressgateway -o jsonpath='{.items[0].metadata.name}') 15032:15032 &
    {{< /text >}}

    打开浏览器访问 [http://localhost:15032](http://localhost:15032)。

1. 要使用 Kubernetes ingress，请指定 Helm chart 选项 `--set tracing.ingress.enabled=true`。

## 使用 Bookinfo 示例产生追踪

1. 当 Bookinfo 应用程序启动并运行时，访问 `http://$GATEWAY_URL/productpage` 一次或多次以生成追踪信息。

1. 从顶部面板的 **Service Name** 下拉列表中选择一个感兴趣的 service （或 'all'），并点击 **Find Traces**：

  {{< image link="./istio-tracing-list-zipkin.png" caption="追踪仪表盘" >}}

1. 点击位于最上面的最近一次追踪，查看对应最近一次访问  `/productpage` 的详细信息：

    latest request to the `/productpage`:

     {{< image link="./istio-tracing-details-zipkin.png" caption="详细追踪视图" >}}

1. 追踪信息由一组 span 组成，每个 span 对应一个 Bookinfo service。这些 service 在执行 `/productpage` 请求时被调用，或是 Istio 内部组件，例如：`istio-ingressgateway`、`istio-mixer`,、`istio-policy`。

## 清理

1. 停止任何可能还在运行的 `kubectl port-forward` 进程：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

1. 如果您没有计划探索任何接下来的任务，请参考 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理)中的说明，关闭整个应用程序。

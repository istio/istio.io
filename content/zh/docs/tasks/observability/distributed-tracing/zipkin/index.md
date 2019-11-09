---
title: Zipkin
description: 学习如何通过配置代理的方式向 Zipkin 发送追踪请求。
weight: 10
keywords: [telemetry,tracing,zipkin,span,port-forwarding]
aliases:
    - /zh/docs/tasks/zipkin-tracing.html
---

完成本文后，不管你应用采用的是什么开发语言、框架以及平台，你将了解如何通过 Zipkin 来给你的应用构建分布式追踪。

本文使用示例 [Bookinfo](/zh/docs/examples/bookinfo/) 来演示。

学习 Istio 如何处理追踪，请访问 [概述](../overview/).

## 开始之前 {#before-you-begin}

1.为了安装 Istio, 根据向导[安装指南](/zh/docs/setup/install/istioctl)并配置：

​      a) 测试环境可以给 helm install 命令选项配置 --set tracing.enabled=true 与 --set tracing.provider=zipkin，做到开箱即用。
​    
​     b) 生产环境可以通过给 helm install 命令选项配置 --set global.tracer.zipkin.address=<zipkin-collector-service>.<zipkin-collector-namespace>:9411 来使用已有的 Zipkin 实例。
​    
{{< warning >}}
​    开启追踪的同时，可以设置 Istio 追踪的采样率。
​    使用 `pilot.traceSampling` 选项设置采样率. 默认采样率是 1%。
{{< /warning >}}
​    

2.部署 [Bookinfo](/docs/examples/bookinfo/#deploying-the-application) 应用示例。

## 访问 dashboard {#accessing-the-dashboard}

[远程访问遥测插件](/zh/docs/tasks/observability/gateways) 详细描述了如何通过网关配置对Istio插件的访问。同样, 为了能够使用 Kubernetes ingress, 在安装时需要指定 `--set values.tracing.ingress.enabled=true` 选项。

为了测试（临时访问），你可以使用 port-forwarding。 假如你已经将 Zipkin 部署到 `istio-system`  命名空间中，使用以下命令:

{{< text bash >}}
$ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=zipkin -o jsonpath='{.items[0].metadata.name}') 15032:9411
{{< /text >}}

打开浏览器访问 [http://localhost:15032](http://localhost:15032).

## 使用 Bookinfo 示例生成追踪{#generating-traces-using-the-Bookinfo-sample}

1.当 Bookinfo 应用启动并运行后，访问 `http://$GATEWAY_URL/productpage` 地址若干次以生成追踪信息。

为了能够追踪数据，你必须向你的服务发送请求。请求的次数取决于Istio配置的采样率。采样率在你安装 Istio 的时候配置。默认情况下采样率为1%。你至少需要发送100个请求才能看到第一个追踪信息。为了发送100个请求给 productpage 服务，请使用下面的命令：

{{< text bash >}}  
$ for i in `seq 1 100`; do curl -s -o /dev/null http://$GATEWAY_URL/productpage; done
{{< /text >}}

2.在面板顶部，从 **Service Name** 下拉列表中选择感兴趣的服务 (或者选择 'all')  并点击
**Find Traces**：

{{< image link="./istio-tracing-list-zipkin.png" caption="Tracing Dashboard" >}}

3.点击顶部最近的追踪，可以看到最近一次对 /productpage 的请求详情:

{{< image link="./istio-tracing-details-zipkin.png" caption="Detailed Trace View" >}}
    

4.一次追踪由多个 spans 组成，每个 span 等同于一个 Bookinfo 服务，在对 /productpage 请求期间会调用这些 span，或者被 Istio 内部组件调用。例如：`istio-ingressgateway`。

## 清理 {#cleanup}

1.  杀死仍在运行的进程 `kubectl port-forward` ：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

1.  如果你不继续浏览后面的任务，参考
    [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup) 文档来关闭应用程序。


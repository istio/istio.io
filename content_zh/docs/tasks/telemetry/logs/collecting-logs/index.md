---
title: 收集日志
description: 这一任务讲述如何配置 Istio，进行日志的收集工作。
weight: 10
keywords: [telemetry,logs]
---

本任务展示了配置 Istio，对网格内服务的遥测数据进行自动收集的方法。在任务的后一部分，会创建一个新的指标以及新的日志流，并在网格内的服务被调用时触发收集过程。

这里会使用 [Bookinfo](/zh/docs/examples/bookinfo/) 作为示例应用。

## 开始之前

* 在集群之中[安装 Istio](/zh/docs/setup)。本文中假设 Mixer 使用的是缺省配置（`--configDefaultNamespace=istio-system`）。如果使用的是不同的值，需要根据实际情况对文中提及的的配置和命令进行变更。

## 收集新的日志数据

1. 新建一个 YAML 文件，用来配置新的指标以及数据流，Istio 将会进行自动生成和收集的工作。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/log-entry.yaml@
    {{< /text >}}

    {{< warning >}}
    如果您使用 Istio 1.1.2 或更早版本，请使用以下配置：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/log-entry-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

1. 向示例应用发送流量。

    在浏览器中打开 Bookinfo 应用的 product 页面：`http://$GATEWAY_URL/productpage`，或者使用如下的等价命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1. 检查请求过程中生成和处理的日志流。

    在 Kubernetes 环境中，像这样在 `istio-telemetry` pods 中搜索日志：

    {{< text bash json >}}
    $ kubectl logs -n istio-system -l istio-mixer-type=telemetry -c mixer | grep "newlog" | grep -v '"destination":"telemetry"' | grep -v '"destination":"pilot"' | grep -v '"destination":"policy"' | grep -v '"destination":"unknown"'
    {"level":"warn","time":"2018-09-15T20:46:36.009801Z","instance":"newlog.xxxxx.istio-system","destination":"details","latency":"13.601485ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
    {"level":"warn","time":"2018-09-15T20:46:36.026993Z","instance":"newlog.xxxxx.istio-system","destination":"reviews","latency":"919.482857ms","responseCode":200,"responseSize":295,"source":"productpage","user":"unknown"}
    {"level":"warn","time":"2018-09-15T20:46:35.982761Z","instance":"newlog.xxxxx.istio-system","destination":"productpage","latency":"968.030256ms","responseCode":200,"responseSize":4415,"source":"istio-ingressgateway","user":"unknown"}
    {{< /text >}}

### 理解日志配置

在此任务中，您添加了 Istio 配置，指示 Mixer 自动为网格中的所有流量生成并报告新的日志流。

添加的配置控制了三个 Mixer 功能：

1. 从 Istio 属性生成 *instances*（在此示例中为日志条目）

1. 创建 *handlers*（配置的 Mixer 适配器），能够处理生成的*instances*

1. 根据一组 *rules* 将 *instances* 发送给 *handlers*

日志配置要求 Mixer 把日志发送给 stdout。它使用了三个部分的配置：**instance** 配置、**handler** 配置以及 **rule** 配置。

配置中的 `kind: logentry` 一节定义了生成日志条目（命名为 `newlog` 的 instance）的格式。这个 instance 配置告知 Mixer 如何根据请求过程中 Envoy 报告的属性生成日志条目。

`severity` 参数用来指定生成的 `logentry` 的日志级别。在本例中使用的是一个常量 `"warning"`。这个值会被映射到支持日志级别数据的 `logentry` handler 中。

`timestamp` 参数为所有日志条目提供了时间信息。在本例中，时间从 Envoy 提供的 `request.time` 属性得到。

`variables` 参数让运维人员可以配置每个 `logentry` 中应该包含什么数据。一系列的表达式控制了从 Istio 属性以及常量映射和组成 `logentry` 的过程。在本文中，每个 `logentry` 都有一个 `latency` 字段，这个字段是从 `response.duration` 属性中得来的。如果 `response.duration` 中没有值，`latency` 字段就会设置为 `0ms`。

`kind: stdio` 这一段配置定义了一个叫做 `newhandler` 的 handler。Handler 的 `spec`
 配置了 `stdio` 适配器收到 `logentry` instance 之后的处理方法。 `severity_levels` 参数控制了 `logentry` 中 `severity` 字段的映射方式。这里的常量 `"warning"` 映射为 `WARNING` 日志级别。`outputAsJson` 参数要求适配器生成 JSON 格式的日志。

`kind: rule` 部分定义了命名为 `newlogstdio` 的 `rule` 对象。这个对象引导 Mixer 把所有 `newlog.logentry` instance 发送给 `newhandler.stdio` handler。因为 `match` 参数取值为 `true`，所以网格中所有的请求都会执行这一对象。

`match: true` 表达式的含义是，这一对象的执行无需过滤，对所有请求都会生效。在 `spec` 中省略 `match` 参数和设置 `match: true` 是等效的。这里的显示声明，目的是展示在 rule 控制过程中 `match` 表达式的使用方法。

## 清理

* 移除新的遥测配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/log-entry.yaml@
    {{< /text >}}

    如果您使用的是 Istio 1.1.2 或之前：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/log-entry-crd.yaml@
    {{< /text >}}

*   删除任何可能仍在运行的 `kubectl port-forward` 进程：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* 如果不准备进一步的探索其他任务，可参照 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理) 的介绍关闭应用。

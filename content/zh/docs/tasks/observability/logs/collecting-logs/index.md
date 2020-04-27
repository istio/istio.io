---
title: 收集日志
description: 本任务向您展示如何配置 Istio 来收集和定制日志。
weight: 10
keywords: [telemetry,logs]
aliases:
 - /zh/docs/tasks/telemetry/logs/collecting-logs/
---

本任务展示如何配置 Istio 来自动地收集网格中服务的遥测指标。任务的最后，将为调用网格内部的服务打开一个新的日志流。

全文以 [Bookinfo](/zh/docs/examples/bookinfo/) 作为示例应用。

## 开始之前{#before-you-begin}

* 在集群中[安装 Istio](/zh/docs/setup) 并部署一个应用。本任务假定在默认配置（`--configDefaultNamespace=istio-system`）中安装了 Mixer。如果您使用了不同的配置，请更新本任务中配置文件和命令的对应项与之匹配。

## 收集新的日志数据{#collecting-new-logs-data}

1. 为新日志流生效一个 YAML 配置文件，Istio 将自动生成并收集日志信息。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/log-entry.yaml@
    {{< /text >}}

    {{< warning >}}
    如果您使用 Istio 1.1.2 或更早前的版本，请使用下面的配置文件：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/log-entry-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

1. 向示例应用发送流量。

    以 Bookinfo 为例，在浏览器中访问 `http://$GATEWAY_URL/productpage` 或执行如下命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1. 验证是否已经生成了日志流并且正向其中不断增添请求。

    在 Kubernetes 环境中，搜索 `istio-telemetry` pods 的日志信息，如下所示：

    {{< text bash json >}}
    $ kubectl logs -n istio-system -l istio-mixer-type=telemetry -c mixer | grep "newlog" | grep -v '"destination":"telemetry"' | grep -v '"destination":"pilot"' | grep -v '"destination":"policy"' | grep -v '"destination":"unknown"'
    {"level":"warn","time":"2018-09-15T20:46:36.009801Z","instance":"newlog.xxxxx.istio-system","destination":"details","latency":"13.601485ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
    {"level":"warn","time":"2018-09-15T20:46:36.026993Z","instance":"newlog.xxxxx.istio-system","destination":"reviews","latency":"919.482857ms","responseCode":200,"responseSize":295,"source":"productpage","user":"unknown"}
    {"level":"warn","time":"2018-09-15T20:46:35.982761Z","instance":"newlog.xxxxx.istio-system","destination":"productpage","latency":"968.030256ms","responseCode":200,"responseSize":4415,"source":"istio-ingressgateway","user":"unknown"}
    {{< /text >}}

## 理解日志配置文件{#understanding-the-logs-configuration}

在本任务中，您新增了 Istio 配置来通知 Mixer 自动生成并报告一个新的日志流，以记录网格内的所有请求。

新增配置控制 Mixer 的三项功能：

1. 基于 Istio 的属性信息，生成 *实例* （本示例中，指的是日志项）。

1. 创建 *handler* （配置好的 Mixer 适配器），处理生成的 *实例* 。

1. 根据一组 *规则* ，将 *实例* 分配给 *handler* 。

日志配置文件指示 Mixer 将日志项发送到标准输出。其中使用了三段（或块）配置：*实例* 配置，*handler* 配置以及 *规则* 配置。

配置段 `kind: instance` 为生成的日志项（或 *实例* ）定义了一个模式，名为 `newlog`。实例配置通知 Mixer 如何基于 Envoy 报告的属性信息，为请求生成日志项。

参数 `severity` 用于为生成的 `logentry` 标识日志级别。在本示例中，使用了一个字面表达，值为 “warn”。`logentry` *handler* 将把该字面值映射为其支持的日志级别。

参数 `timestamp` 提供所有日志项的时间信息。在本示例中，根据 Envoy 提供的信息，时间为属性 `request.time` 的值。

参数 `variables` 允许运维人员配置应该在每个 `logentry` 中显示的信息。一组表达式负责管理从 Istio 属性值和字面值到构成 `logentry` 对应值的映射关系。在本示例中，每个 `logentry` 实例都包含一个域名 `latency`，其对应着属性 `response.duration` 的值。如果没有已知的 `response.duration` 属性值，则将 `latency` 域值设置为 `0ms`。

配置段 `kind: handler` 定义了一个名为 `newloghandler` 的 *handler* 。Handler `spec` 负责配置 `stdio` 编译的适配器代码如何处理接收到的 `logentry` 实例。参数 `severity_levels` 负责管理 `logentry` 的 `severity` 域值如何映射到所支持的日志级别。本示例中，“warn” 映射为日志级别 “WARNING”。参数 `outputAsJson` 指示适配器生成 JSON 格式的日志行。

配置段 `kind: rule` 定义了一个新 *规则* ，名为 `newlogstdio`。该规则指示 Mixer 将所有 `newlog` 实例发送给 handler `newloghandler`。由于参数 `match` 被设置为 `true`，该规则对网格中的所有请求都生效。

规则规范中的 `match: true` 表达式无需对所有请求配置一个执行规则。删掉 `spec` 中的 `match` 参数等价于设置了 `match: true`。本案例中将其包含在 `spec` 中，是为了说明如何使用 `match` 表达式来控制执行规则。

## 清除{#cleanup}

*   删除新的日志配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/log-entry.yaml@
    {{< /text >}}

    若使用 Istio 1.1.2 或更早版本：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/log-entry-crd.yaml@
    {{< /text >}}

*   若无后续任务，请参考
    [Bookinfo cleanup](/zh/docs/examples/bookinfo/#cleanup) 命令关掉应用。

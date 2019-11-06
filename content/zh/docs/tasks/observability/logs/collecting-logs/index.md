---
title: 日志收集
description: 这篇文档讲述如何配置 Istio 来获取和自定义日志。
weight: 10
keywords: [telemetry,logs]
aliases:
 - /zh/docs/tasks/telemetry/logs/collecting-logs/
---

此任务说明如何配置 Istio 以自动收集网格中的遥测数据。在阅读完这篇文档后，您可以启用新的日志流去调用网格中的服务。

使用 [Bookinfo](/zh/docs/examples/bookinfo/) 示例作为整个任务的示例应用程序。

## 开始之前{#before-you-begin}

* 在您的集群中 [安装 Istio](/zh/docs/setup) 并部署一个应用程序。
  此任务假定在默认配置 (`--configDefaultNamespace=istio-system`) 中设置了 Mixer。
  如果您使用其他值，修改此任务中的配置和命令以匹配该值。

## 收集新的记录数据{#collecting-new-logs-data}

1.  配置并应用一个 YAML 文件使 Istio 可以自动地生成和收集新的日志流。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/log-entry.yaml@
    {{< /text >}}

    {{< warning >}}
    If you use Istio 1.1.2 or prior, please use the following configuration instead:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/log-entry-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

1.  将流量发送到示例应用程序。

    有关 Bookinfo 示例信息，请在您的网页浏览器中访问 `http://$GATEWAY_URL/productpage` 或者输出以下命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  验证是否已创建日志流并正在为其填充日志流要求。

    在 Kubernetes 环境中，通过日志搜索 `istio-telemetry` pod，如下所示：

    {{< text bash json >}}
    $ kubectl logs -n istio-system -l istio-mixer-type=telemetry -c mixer | grep "newlog" | grep -v '"destination":"telemetry"' | grep -v '"destination":"pilot"' | grep -v '"destination":"policy"' | grep -v '"destination":"unknown"'
    {"level":"warn","time":"2018-09-15T20:46:36.009801Z","instance":"newlog.xxxxx.istio-system","destination":"details","latency":"13.601485ms","responseCode":200,"responseSize":178,"source":"productpage","user":"unknown"}
    {"level":"warn","time":"2018-09-15T20:46:36.026993Z","instance":"newlog.xxxxx.istio-system","destination":"reviews","latency":"919.482857ms","responseCode":200,"responseSize":295,"source":"productpage","user":"unknown"}
    {"level":"warn","time":"2018-09-15T20:46:35.982761Z","instance":"newlog.xxxxx.istio-system","destination":"productpage","latency":"968.030256ms","responseCode":200,"responseSize":4415,"source":"istio-ingressgateway","user":"unknown"}
    {{< /text >}}

## 理解日志配置{#understanding-the-logs-configuration}

在此任务中，添加 Istio 配置来指示 Mixer 为网格内的所有流量自动生成并报告新的日志流。

添加的配置控制了 Mixer 的三项功能：

1. 从 Istio 属性中生成 *instances* （在此例中，为日志条目）

1. 创建 *handlers* （配置了 Mixer 的适配器） 来处理生成的 *instances*

1. 根据一组 *rules* 向 *handlers* 分配 *instances*

日志配置指示 Mixer 将日志条目发送给 stdout。
它使用配置中的三个节（或块）：*instances* 配置、*handler* 配置和 *rule* 配置。

配置中的 `kind: instance` 节给生成名为 `newlog` 的日志条目 （或者 *instances*） 定义了一个概要。
此实例讲述 Mixer 怎么基于属性报告使用 Envoy 为请求生成日志条目。

`severity` 参数用来指出任何生成 `logentry` 的日志级别。
在此例中，使用了文字值 `"warning"`。
该值将通过 `logentry` *handler* 映射到支持的日志记录级别。

`timestamp` 参数提供了所有日志条目的时间信息。
在此示例中，时间通过属性值 `request.time` 提供，例如由 Envoy 提供。

`variables` 参数允许操作员配置值， 包括在每一个应设置的 `logentry` 中配置。
一组表达式控制着从 Istio 属性和文字值到构成 `logentry` 值的映射。
在此例中，每一个 `logentry` 实例都有一个名为 `latency` 的字段填充来自属性 `response.duration` 的值。
如果 `response.duration` 没有已知值，则 `latency` 字段将被设置为 `0ms` 持续时间。

配置中的 `kind: handler` 节定了一个名为 `newloghandler` 的 *handler*。
该处理者 `spec` 配置 `stdio` 编译的适配器代码处理接收到的 `logentry` 实例。
参数 `severity_levels` 控制如何将 `severity` 字段的 `logentry` 值映射到支持的日志记录级别。
在这里，`"warning"` 值被映射到 `WARNING` 日志级别。
`outputAsJson` 参数指示适配器生成 JSON 格式的日志行。

配置中的 `kind: rule` 节定义了一个名为 `newlogstdio` 的新 *rule*。
该规则指导 Mixer 将所有的 `newlog` 实例发送给 `newloghandler` 处理者。
由于 `match` 参数被设置为 `true`，所以对网格内的所有请求都执行该规则。

在规则规范中，表达式 `match: true` 不需要配置一个规则使所有请求去执行。
在 `spec` 中省略整个参数 `match` 等价于设置 `match: true`。
在这里，也包括了说明如何使用 `match` 表达式来控制规执行。

## 清理{#cleanup}

*   移除新日志配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/log-entry.yaml@
    {{< /text >}}

    如果您正在使用 Istio 1.1.2 版本或者优先版本：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/log-entry-crd.yaml@
    {{< /text >}}

*   移除任何可能仍在运行的 `kubectl port-forward` 进程：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

*   如果您不打算探索任何后续任务，参考 [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup) 说明关闭此应用程序。

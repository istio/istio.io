---
title: 收集指标和日志
description: 这一任务讲述如何配置 Istio，进行指标和日志的收集工作。
weight: 20
keywords: [telemetry,metrics]
---

本任务展示了配置 Istio，对网格内服务的遥测数据进行自动收集的方法。在任务的后一部分，会创建一个新的指标以及新的日志流，并在网格内的服务被调用时触发收集过程。

这里会使用 [Bookinfo](/zh/docs/examples/bookinfo/) 作为示例应用。

## 开始之前

* 在集群之中[安装 Istio](/zh/docs/setup)。本文中假设 Mixer 使用的是缺省配置（`--configDefaultNamespace=istio-system`）。如果使用的是不同的值，需要根据实际情况对文中提及的的配置和命令进行变更。

## 收集新的遥测数据

1. 新建一个 YAML 文件，用来配置新的指标以及数据流，Istio 将会进行自动生成和收集的工作。

    以文件名 `new_telemetry.yaml` 保存下面的代码：

    {{< text yaml >}}
    # 指标 instance 的配置
    apiVersion: "config.istio.io/v1alpha2"
    kind: metric
    metadata:
      name: doublerequestcount
      namespace: istio-system
    spec:
      value: "2" # 每个请求计数两次
      dimensions:
        reporter: conditional((context.reporter.kind | "inbound") == "outbound", "client", "server")
        source: source.workload.name | "unknown"
        destination: destination.workload.name | "unknown"
        message: '"twice the fun!"'
      monitored_resource_type: '"UNSPECIFIED"'
    ---
    # prometheus handler 的配置
    apiVersion: "config.istio.io/v1alpha2"
    kind: prometheus
    metadata:
      name: doublehandler
      namespace: istio-system
    spec:
      metrics:
      - name: double_request_count # Prometheus 指标名称
        instance_name: doublerequestcount.metric.istio-system # Mixer Instance 名称（全限定名称）
        kind: COUNTER
        label_names:
        - reporter
        - source
        - destination
        - message
    ---
    # 将指标 Instance 发送给 prometheus handler 的 rule 对象
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: doubleprom
      namespace: istio-system
    spec:
      actions:
      - handler: doublehandler.prometheus
        instances:
        - doublerequestcount.metric
    {{< /text >}}

1. 把新配置推送给集群。

    {{< text bash >}}
    $ kubectl apply -f new_metrics.yaml
    Created configuration metric/istio-system/doublerequestcount at revision 1973035
    Created configuration prometheus/istio-system/doublehandler at revision 1973036
    Created configuration rule/istio-system/doubleprom at revision 1973037
    {{< /text >}}

1. 向示例应用发送流量。

    在浏览器中打开 Bookinfo 应用的 product 页面：`http://$GATEWAY_URL/productpage`，或者使用如下的等价命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1. 复查新指标的生成和收集情况。

    在 Kubernetes 环境中，使用下面的命令为 Prometheus 设置端口转发：

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
    {{< /text >}}

    使用 [Prometheus 界面](http://localhost:9090/graph#%5B%7B%22range_input%22%3A%221h%22%2C%22expr%22%3A%22istio_double_request_count%22%2C%22tab%22%3A1%7D%5D)查看新的指标。

    上面的链接会打开 Prometheus 界面并查询 `istio_double_request_count` 的值。**Console** 标签页会以表格形式进行数据展示，类似：

    {{< text plain >}}
    istio_double_request_count{destination="details-v1",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="client",source="productpage-v1"}   8
    istio_double_request_count{destination="details-v1",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="productpage-v1"}   8
    istio_double_request_count{destination="istio-policy",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="details-v1"}   4
    istio_double_request_count{destination="istio-policy",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="istio-ingressgateway"}   4
    {{< /text >}}

    要查询更多的指标数据，可以参考[查询 Istio 指标](/zh/docs/tasks/telemetry/metrics/querying-metrics/)任务

## 理解遥测配置

这个任务中使用 Istio 配置，让 Mixer 自动为所有的网格内流量生成和报告新的指标以及新的日志流。

配置中使用了三种 Mixer 功能：

1. 从 Istio 属性中生成 **instance**（这里是指标值以及日志条目）

1. 创建 **handler**（配置 Mixer 适配器），用来处理生成的 **instance**

1. 根据一系列的 **rule**，把 **instance** 传递给 **handler**。

### 理解指标配置

指标的配置让 Mixer 把指标数值发送给 Prometheus。其中包含三块内容：**instance** 配置、**handler** 配置以及 **rule** 配置。

`kind: metric` 为指标值（或者 **instance**）定义了结构，命名为 `doublerequestcount`。Instance 配置告诉 Mixer 如何为所有请求生成指标。指标来自于 Envoy 汇报的属性（然后由 Mixer 生成）。

`doublerequestcount.metric` 配置让 Mixer 给每个 instance 赋值为 `2`。因为 Istio 为每个请求都会生成 instance，这就意味着这个指标的记录的值等于收到请求数量的两倍。

每个 `doublerequestcount.metric` 都有一系列的 `dimension`。`dimension` 提供了一种为不同查询和需求对指标数据进行分割、聚合以及分析的方式。例如在对应用进行排错的过程中，可能只需要目标为某个服务的请求进行报告。这种配置让 Mixer 根据属性值和常量为 `dimension` 生成数值。例如 `source` 这个 `dimension`，他首先尝试从 `source.service` 属性中取值，如果取值失败，则会使用缺省值 `"unknown"`。而 `message` 这个 `dimension`，所有的 instance 都会得到一个常量值：`"twice the fun!"`。

`kind: prometheus` 这一段定义了一个叫做 `doublehandler` 的 **handler**。`spec` 中配置了 Prometheus 适配器收到指标之后，如何将指标 `instance` 转换为 Prometheus 能够处理的指标数据格式的方式。配置中生成了一个新的 Prometheus 指标，取名为 `double_request_count`。Prometheus 适配器会给指标名称加上 `istio_` 前缀，因此这个指标在 Prometheus 中会显示为 `istio_double_request_count`。指标带有三个标签，和 `doublerequestcount.metric` 的 `dimension` 配置相匹配。

对于 `kind: prometheus` 来说，Mixer 中的 instance 通过 `instance_name` 来匹配 Prometheus 指标。`instance_name` 必须是一个全限定名称（例如：`doublerequestcount.metric.istio-system`）

`kind: rule` 部分定义了一个新的叫做 `doubleprom` 的 `rule` 对象。这个对象要求 Mixer 把所有的  `doublerequestcount.metric` 发送给 `doublehandler.prometheus`。因为 `rule` 中没有包含 `match` 字段，并且身处缺省配置的命名空间内（`istio-system`），所以这个 `rule` 对象对所有的网格内通信都会生效。

### 理解日志配置

日志配置要求 Mixer 把日志发送给 stdout。它使用了三个部分的配置：**instance** 配置、**handler** 配置以及 **rule** 配置。

配置中的 `kind: logentry` 一节定义了生成日志条目（命名为 `newlog` 的 instance）的格式。这个  instance 配置告知 Mixer 如何根据请求过程中 Envoy 报告的属性生成日志条目。

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
    $ kubectl delete -f new_metrics.yaml
    {{< /text >}}

*   删除任何可能仍在运行的 `kubectl port-forward` 进程：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* 如果不准备进一步的探索其他任务，可参照 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理) 的介绍关闭应用。

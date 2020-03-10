---
title: 采集指标
description: 此任务向您展示如何配置 Istio 以采集和自定义指标。
weight: 10
keywords: [telemetry,metrics]
aliases:
    - /zh/docs/tasks/metrics-logs.html
    - /zh/docs/tasks/telemetry/metrics-logs/
    - /zh/docs/tasks/telemetry/metrics/collecting-metrics/
---

此任务说明如何配置 Istio 以自动收集网格中服务的遥测。
在此任务结束时，将为网格中的服务调用启用新的指标。

在整个任务中，[Bookinfo](/zh/docs/examples/bookinfo/) 将作为示例应用程序。

## 开始之前{#before-you-begin}

* [安装 Istio](/zh/docs/setup) 到您的集群并部署一个应用。该任务假定 Mixer 已经用默认配置（`--configDefaultNamespace=istio-system`）设置好了。如果您使用的不同的值，请更新本任务中的配置和命令以匹配该值。

## 采集新的指标{#collecting-new-metrics}

1.  应用配置新指标的 YAML 文件，该指标将由 Istio 自动生成和采集。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/metrics.yaml@
    {{< /text >}}

    {{< warning >}}
    如果您使用 Istio 1.1.2 或更早版本，请改为使用以下配置：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/metrics-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

1.  发送流量到示例应用。

    对于 Bookinfo 示例，从浏览器访问 `http://$GATEWAY_URL/productpage` 或使用下列命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  确认新的指标已被生成并采集。

    对于 Kubernetes 环境，执行以下命令为 Prometheus 设置端口转发：

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
    {{< /text >}}

    通过 [Prometheus UI](http://localhost:9090/graph#%5B%7B%22range_input%22%3A%221h%22%2C%22expr%22%3A%22istio_double_request_count%22%2C%22tab%22%3A1%7D%5D) 查看新指标的值。

    上述链接打开 Prometheus UI 并执行对 `istio_double_request_count` 指标值的查询语句。
    **Console** 选项卡中显示的表格包括了一些类似如下的条目：

    {{< text plain >}}
    istio_double_request_count{destination="details-v1",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="client",source="productpage-v1"}   8
    istio_double_request_count{destination="details-v1",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="productpage-v1"}   8
    istio_double_request_count{destination="istio-policy",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="details-v1"}   4
    istio_double_request_count{destination="istio-policy",instance="172.17.0.12:42422",job="istio-mesh",message="twice the fun!",reporter="server",source="istio-ingressgateway"}   4
    {{< /text >}}

    更多关于查询 Prometheus 指标值的信息，请参考[查询 Istio 指标](/zh/docs/tasks/observability/metrics/querying-metrics/)任务。

## 理解指标配置{#understanding-the-metrics-configuration}

在此任务中，您添加了 Istio 配置，该配置指示 Mixer 为网格中的所有流量自动生成并报告新的指标。

添加的配置控制 Mixer 功能的三个部分：

1. 生成 Istio 属性的 *instances* （本任务中为指标的值）

1. 创建能够处理生成的 *instances* 的 *handlers* （配置的 Mixer 适配器）

1. 根据一组 *rules* 向 *handlers* 分配 *instances*

以上指标配置指示 Mixer 将指标值发送到 Prometheus。
它使用三个节（或块）进行配置：*instance* 配置、*handler* 配置和 *rule* 配置。

配置的 `kind: instance` 节定义了一种模式，用于为名为 `doublerequestcount` 的新指标生成指标值（或 *instances* ）。
该 instance 配置告诉 Mixer *如何* 根据 Envoy 报告（由 Mixer 自己生成）的属性为任何给定请求生成指标值。

对于 `doublerequestcount` 的每个 instance，配置指示 Mixer 为它提供值 `2`。
由于 Istio 为每个请求生成一个 instance，这意味着该指标记录的值等于接收到的请求总数的两倍。

为每个 `doublerequestcount` instance 指定了一组 `dimensions`。
Dimensions 提供了一种根据不同需求和查询方向来切分、汇总和分析指标数据的方法。
例如，在对应用程序行为进行问题排查时，可能仅需考虑对特定目标服务的请求。

该配置指示 Mixer 根据属性值和文字值来填充这些 dimension 的值。
例如，对于 `source` dimension，新配置要求从 `source.workload.name` 属性中获取该值。
如果未填充该属性值，则该规则指示 Mixer 使用默认值 `"unknown"`。
对于 `message` dimension，所有 instances 将使用文字值 `"twice the fun!"`。

配置的 `kind: handler` 节定义了一个名为 `doublehandler` 的 *handler* 。
Handler 的 `spec` 字段配置了 Prometheus 适配器代码是如何将收到的指标 instances 转换为 Prometheus 格式（Prometheus 后端可以处理）的值。
此配置指定了一个名为 `double_request_count` 的新 Prometheus 指标。
Prometheus 适配器在所有指标名称之前都添加了 `istio_` 命名空间，因此该指标将在 Prometheus 中显示为 `istio_double_request_count`。
该指标具有三个标签，这些标签与为 `doublerequestcount` instance 配置的 dimension 相匹配。

Mixer instances 通过 `instance_name` 参数与 Prometheus 指标匹配。
`instance_name` 值必须是 Mixer instances 的标准名称（例如：`doublerequestcount.instance.istio-system`）。

配置的 `kind: rule` 节定义了一个名为 `doubleprom` 的 *rule* 。
该规则指示 Mixer 将所有 `doublerequestcount` instances 发送到 `doublehandler` 处理程序。
因为规则中没有 `match` 子句，并且该规则位于已配置的默认配置命名空间（`istio-system`）中，所以将为网格中的所有请求执行该规则。

## 清除{#cleanup}

*   移除新指标的配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/metrics.yaml@
    {{< /text >}}

    如果您使用 Istio 1.1.2 或更早版本：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/metrics-crd.yaml@
    {{< /text >}}

*   移除任何还在运行的 `kubectl port-forward` 程序：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

*   如果您不打算继续浏览后续的任务，请参考 [Bookinfo 清除](/zh/docs/examples/bookinfo/#cleanup)说明以关闭该应用。

---
title: 查询 Prometheus 的指标
description: 此任务说明如何使用 Prometheus 查询 Istio 指标。
weight: 30
keywords: [telemetry,metrics]
---

此任务说明如何使用 Prometheus 查询 Istio 指标, 作为此任务的一部分，使用基于 Web 的界面进行指标查询。

[Bookinfo](/docs/examples/bookinfo/) 示例应用程序在整个任务中用作示例应用程序。

## 前提条件

[安装 Istio](/docs/setup/) 在您的群集中并部署应用程序。

## 查询 Istio 度量标准

1.  验证 `prometheus` 服务是否在您的群集中运行（从 0.8 开始， 默认情况下 `prometheus` 设置包含在 `istio.yaml` 和 `istio-demo-auth.yaml` 中）

    在 Kubernetes 环境中，执行以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get svc prometheus
    NAME         CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
    prometheus   10.59.241.54   <none>        9090/TCP   2m
    {{< /text >}}

1.  将流量发送到服务网格。

    对于 Bookinfo 示例，请在 Web 浏览器中访问 `http://$GATEWAY_URL/productpage` 或发出以下命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

    > `$GATEWAY_URL` 是[Bookinfo](/docs/examples/bookinfo/) 示例中设置的值。

1.  打开 Prometheus UI。

    在 Kubernetes 环境中，执行以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
    {{< /text >}}

    在Web浏览器中访问 [http://localhost:9090/graph](http://localhost:9090/graph)。

1.  执行 Prometheus 查询。

    在网页顶部的 "Expression” 输入框中，输入文本： `istio_request_count` , 然后，单击 **Execute** 按钮。

结果将类似于：

{{< image width="100%" ratio="39.36%"
    link="/docs/tasks/telemetry/querying-metrics/prometheus_query_result.png"
    caption="Prometheus 查询结果"
    >}}

其他查询尝试：

-   对 `productpage` 服务的所有请求的总数：

    {{< text plain >}}
    istio_request_count{destination_service="productpage.default.svc.cluster.local"}
    {{< /text >}}

-   对 `reviews` 服务的 `v3` 的所有请求的总数：

    {{< text plain >}}
    istio_request_count{destination_service="reviews.default.svc.cluster.local", destination_version="v3"}
    {{< /text >}}

    此查询返回 `reviews` 服务 v3 的所有请求的当前总计数。

-   过去 5 分钟内对所有 `productpage` 服务的请求率：

    {{< text plain >}}
    rate(istio_request_count{destination_service=~"productpage.*", response_code="200"}[5m])
    {{< /text >}}

### 关于 Prometheus 的附加组件

Mixer 中内置了 Prometheus 适配器，这一适配器将生成的指标值以端点的形式公开出来；Prometheus 插件则是一个预配置的 Prometheus 服务器，他一方面从上述 Mixer 端点抓取 Istio 指标，另一方面还为 Istio 指标提供了持久化存储和查询的服务。

配置好的 Prometheus 插件会抓取以下三个端点：

1. *istio-mesh* (`istio-mixer.istio-system:42422`): 所有 Mixer 生成的网格指标。
1. *mixer* (`istio-mixer.istio-system:9093`):  所有特定于 Mixer 的指标, 用于监控 Mixer 本身。
1. *envoy* (`istio-mixer.istio-system:9102`):  envoy 生成的原始统计数据（并从 `statsd` 转换为 `prometheus` ）。

有关查询 Prometheus 的更多信息，请阅读他们的[查询文档](https://prometheus.io/docs/querying/basics/)。

## 清理

-   删除任何可能仍在运行的 `kubectl port-forward` 进程：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

-   如果您不打算探索任何后续任务，请参阅[Bookinfo 清理](/docs/examples/bookinfo/#cleanup) 说明以关闭应用程序。

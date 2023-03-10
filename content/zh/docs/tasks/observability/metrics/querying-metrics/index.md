---
title: 通过 Prometheus 查询度量指标
description: 本任务介绍如何通过 Prometheus 查询 Istio 度量指标。
weight: 30
keywords: [telemetry,metrics]
aliases:
    - /zh/docs/tasks/telemetry/querying-metrics/
    - /zh/docs/tasks/telemetry/metrics/querying-metrics/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

本任务介绍如何通过 Prometheus 查询 Istio 度量指标。作为任务的一部分，你将通过 web 界面查询度量指标值。

本任务以 [Bookinfo](/zh/docs/examples/bookinfo/) 样本应用作为案例。

## 开始之前{#before-you-begin}

* 在自身集群中[安装 Istio](/zh/docs/setup/) 。
* 安装 [Prometheus Addon](/zh/docs/ops/integrations/prometheus/#option-1-quick-start)。
* 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 应用。

## 查询 Istio 度量指标{#query-mesh-metrics}

1. 验证自身集群中运行着 `prometheus` 服务。

    在 Kubernetes 环境中，执行如下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get svc prometheus
    NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
    prometheus   ClusterIP   10.109.160.254   <none>        9090/TCP   4m
    {{< /text >}}

1. 向网格发送流量。

    以 Bookinfo 为例，在 web 浏览器中访问 `http://$GATEWAY_URL/productpage` 或执行如下命令：

    {{< text bash >}}
    $ curl "http://$GATEWAY_URL/productpage"
    {{< /text >}}

    {{< tip >}}
    `$GATEWAY_URL` 是在 [Bookinfo](/zh/docs/examples/bookinfo/) 应用中设置的值。
    {{< /tip >}}

1. 打开 Prometheus UI。

    在 Kubernetes 环境中，执行如下命令：

    {{< text bash >}}
    $ istioctl dashboard prometheus
    {{< /text >}}

    点击标题中 Prometheus 右侧的 **Graph**。

1. 执行一个 Prometheus 查询。

    在 web 页面顶部的 "Expression" 对话框中，输入文本：

    {{< text plain >}}
    istio_requests_total
    {{< /text >}}

    然后点击 **Execute** 按钮。

结果类似于：

{{< image link="./prometheus_query_result.png" caption="Prometheus 查询结果" >}}

您还可以通过选择 **Execute** 按钮下方的 “图形” 选项卡以图形方式查看查询结果。

{{< image link="./prometheus_query_result_graphical.png" caption="Prometheus 查询结果 - Graphical" >}}

其他查询尝试：

*   请求 `productpage` 服务的总次数：

    {{< text plain >}}
    istio_requests_total{destination_service="productpage.default.svc.cluster.local"}
    {{< /text >}}

*   请求 `reviews` 服务 `v3` 版本的总次数：

    {{< text plain >}}
    istio_requests_total{destination_service="reviews.default.svc.cluster.local", destination_version="v3"}
    {{< /text >}}

    该查询返回所有请求 `reviews` 服务 v3 版本的当前总次数。

*   过去 5 分钟 `productpage` 服务所有实例的请求频次：

    {{< text plain >}}
    rate(istio_requests_total{destination_service=~"productpage.*", response_code="200"}[5m])
    {{< /text >}}

### 关于 Prometheus 插件{#about-the-monitor-add-on}

Prometheus 插件是预先配置抓取 Istio 端点收集指标的 Prometheus 服务器。它提供了一种持久存储和查询 Istio 指标的机制。

有关查询Prometheus的更多信息，请阅读他们的[查询文档](https://prometheus.io/docs/querying/basics/) 。

## 清除{#cleanup}

*   使用 control-C 或以下命令删除可能仍在运行的所有 `istioctl` 进程：

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

*   如果您不打算探索任何后续任务，请参阅 [Bookinfo 清理说明](/zh/docs/examples/bookinfo/#cleanup) 清理说明关闭应用程序。

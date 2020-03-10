---
title: 通过 Prometheus 查询度量指标
description: 本任务介绍如何通过 Prometheus 查询 Istio 度量指标。
weight: 30
keywords: [telemetry,metrics]
aliases:
    - /zh/docs/tasks/telemetry/querying-metrics/
    - /zh/docs/tasks/telemetry/metrics/querying-metrics/
---

本任务介绍如何通过 Prometheus 查询 Istio 度量指标。作为任务的一部分，你将通过 web 界面查询度量指标值。

本任务以 [Bookinfo](/zh/docs/examples/bookinfo/) 样本应用作为案例。

## 开始之前{#before-you-begin}

在自身集群中[安装 Istio](/zh/docs/setup/) 并部署一个应用。

## 查询 Istio 度量指标{#query-mesh-metrics}

1.  验证自身集群中运行着 `prometheus` 服务。

    在 Kubernetes 环境中，执行如下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get svc prometheus
    NAME         CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
    prometheus   10.59.241.54   <none>        9090/TCP   2m
    {{< /text >}}

1.  向网格发送流量。

    以 Bookinfo 为例，在 web 浏览器中访问 `http://$GATEWAY_URL/productpage` 或执行如下命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

    {{< tip >}}
    `$GATEWAY_URL` 是在 [Bookinfo](/zh/docs/examples/bookinfo/) 应用中设置的值。
    {{< /tip >}}

1.  打开 Prometheus UI。

    在 Kubernetes 环境中，执行如下命令：

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
    {{< /text >}}

    在 web 浏览器中访问 [http://localhost:9090/graph](http://localhost:9090/graph)。

1.  执行一个 Prometheus 查询。

    在 web 页面顶部的 "Expression" 对话框中，输入文本：
    `istio_requests_total`。 然后点击 **Execute** 按钮。

结果类似于：

{{< image link="./prometheus_query_result.png" caption="Prometheus Query Result" >}}

其他查询：

-   请求 `productpage` 服务的总次数：

    {{< text plain >}}
    istio_requests_total{destination_service="productpage.default.svc.cluster.local"}
    {{< /text >}}

-   请求 `reviews` 服务 V3 版本的总次数：

    {{< text plain >}}
    istio_requests_total{destination_service="reviews.default.svc.cluster.local", destination_version="v3"}
    {{< /text >}}

    该查询返回所有请求 `reviews` 服务 v3 版本的当前总次数。

-   过去 5 分钟 `productpage` 服务所有实例的请求频次：

    {{< text plain >}}
    rate(istio_requests_total{destination_service=~"productpage.*", response_code="200"}[5m])
    {{< /text >}}

### 关于 Prometheus 插件{#about-the-monitor-add-on}

Mixer 自带一个内嵌的 [Prometheus](https://prometheus.io) 适配器，对外暴露一个端点，负责提供度量指标值服务。 Prometheus 插件是一个提前配置好的 Prometheus 服务器，旨在通过 Mixer 端点收集对外暴露的度量指标。插件提供了持久化存储和 Istio 度量指标查询机制。

Prometheus 插件预配抓捕如下端点：

1. `istio-telemetry.istio-system:42422`: `istio-mesh` 任务返回所有 Mixer 生成的度量指标。
1. `istio-telemetry.istio-system:15014`: `istio-telemetry` 任务返回所有 Mixer 特殊的度量指标。该端点用于监控 Mixer 本身。
1. `istio-proxy:15090`: `envoy-stats` 任务返回 Envoy 生成的原始状态。 Prometheus 被配置来查找对外暴露了 `envoy-prom` 端点的 pods。 在收集过程中，插件配置过滤掉大量 envoy 度量指标，从而限制插件进程的数据量。
1. `istio-pilot.istio-system:15014`: `pilot` 任务返回 Pilot 生成的度量指标。
1. `istio-galley.istio-system:15014`: `galley` 任务返回 Galley 生成的度量指标。
1. `istio-policy.istio-system:15014`: `istio-policy` 任务返回所有策略相关的度量指标。
1. `istio-citadel.istio-system:15014`: `istio-citadel` 任务返回所有 Citadel 生成的度量指标。

更多关于 Prometheus 查询的信息，请阅读 [querying
docs](https://prometheus.io/docs/querying/basics/).

## 清除{#cleanup}

-   删除所有可能运行着的 `kubectl port-forward` 进程：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

-   若不再执行后续任务， 参考
    [Bookinfo cleanup](/zh/docs/examples/bookinfo/#cleanup) 命令关闭应用。

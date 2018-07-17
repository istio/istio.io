---
title: 使用 Grafana 进行指标可视化
description: 此任务说明如何设置和使用 Istio 仪表板来监视网格流量。
weight: 40
keywords: [telemetry,visualization]
---

此任务说明如何设置和使用 Istio 仪表板来监视网格流量, 作为此任务的一部分，您将需要安装 Grafana Istio 附加组件，并使用基于 Web 的界面查看服务网格中的流量数据。

[Bookinfo](/docs/examples/bookinfo/) 示例应用程序在整个任务中用作示例应用程序。

## 前提条件

* 在群集中[安装 Istio](/docs/setup/) 并部署应用程序。
* [安装 Prometheus 附加组件](/docs/tasks/telemetry/querying-metrics/)。

## 查看 Istio 仪表板

1.  要在图形仪表板中查看 Istio 指标，请安装 Grafana 插件。

    在 Kubernetes 环境中，执行以下命令：

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/addons/grafana.yaml
    {{< /text >}}

1.  验证服务是否在群集中运行。

    在 Kubernetes 环境中，执行以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get svc grafana
    NAME      CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    grafana   10.59.247.103   <none>        3000/TCP   2m
    {{< /text >}}

1.  通过 Grafana UI 打开 Istio Dashboard。

    在 Kubernetes 环境中，执行以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &
    {{< /text >}}

    在 Web 浏览器中访问 [http://localhost:3000/dashboard/db/istio-dashboard](http://localhost:3000/dashboard/db/istio-dashboard)。

    Istio 仪表板看起来类似于：

    {{< image width="100%" ratio="56.57%"
        link="/docs/tasks/telemetry/using-istio-dashboard/grafana-istio-dashboard.png"
        caption="Istio Dashboard"
        >}}

1.  将流量发送到服务网格。

    对于 Bookinfo 示例，请在Web浏览器中访问 `http://$GATEWAY_URL/productpage` 或发出以下命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

    刷新页面几次（或发送命令几次）以产生少量流量。

    再看一下 Istio Dashboard, 它应该反映生成的流量, 它看起来类似于下图所示的内容：

    {{< image width="100%" ratio="56.57%"
    link="/docs/tasks/telemetry/using-istio-dashboard/dashboard-with-traffic.png"
    caption="Istio 的流量仪表板"
    >}}

> `$GATEWAY_URL` 是[Bookinfo](/docs/examples/bookinfo/) 示例中设置的值。

### 关于 Grafana 插件

Grafana 插件是 Grafana 的预配置实例, 基本映像（[`grafana/grafana:4.1.2`](https://hub.docker.com/r/grafana/grafana/)已经修改为从安装了 Prometheus 数据源和 Istio Dashboard 开始, Istio 的基本安装文件，特别是 Mixer，带有全局（用于每个服务）指标的默认配置, Istio Dashboard 可与默认的 Istio 指标配置和 Prometheus 后端结合使用。

Istio 仪表板由三个主要部分组成：
1. 全局摘要视图, 本节提供流经服务网格的 HTTP 请求的高级摘要。
1. 网格摘要视图, 本节提供了比全局摘要视图更多的详细信息，允许按服务过滤和选择。
1. 单个服务视图, 本节提供有关网格中每个服务（HTTP和TCP）的请求和响应的度量标准。

有关如何创建，配置和编辑仪表板的更多信息，请参阅 [Grafana文档](https://docs.grafana.org/)。

## 清理

*   在 Kubernetes 环境中，执行以下命令以删除 Grafana 附加组件：

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/addons/grafana.yaml
    {{< /text >}}

*   删除可能正在运行的任何 `kubectl port-forward` 进程：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* 如果您不打算探索任何后续任务，请参阅 [Bookinfo 清理](/docs/examples/bookinfo/#cleanup)说明以关闭应用程序。

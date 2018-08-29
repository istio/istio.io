---
title: 生成服务图
description: 此任务说明如何在 Istio 网格中生成服务图。
weight: 50
keywords: [遥测,可视化]
---

此任务说明如何在Istio网格中生成服务图。
作为此任务的一部分，您将安装 Servicegraph 附加组件,使用基于 Web 的界面查看服务网格的服务图。

[Bookinfo](/zh/docs/examples/bookinfo/) 示例应用程序在整个任务中用作示例应用程序。

## 前提条件

* 在您的集群中[安装 Istio](/zh/docs/setup/) 并部署应用程序。

## 生成服务图

1.  要查看服务网格的图形表示，请安装 Servicegraph 附加组件。

    在Kubernetes环境中，执行以下命令：

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/addons/servicegraph.yaml
    {{< /text >}}

1.  验证服务是否在集群中运行。

    在 Kubernetes 环境中，执行以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get svc servicegraph
    NAME           CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    servicegraph   10.59.253.165   <none>        8088/TCP   30s
    {{< /text >}}

1.  将流量发送到网格。

    对于 Bookinfo 示例，请在 Web 浏览器中访问 `http://$GATEWAY_URL/productpage` 或发出以下命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

    刷新页面几次（或发送命令几次）以产生少量流量。

    > `$GATEWAY_URL` 是[Bookinfo](/zh/docs/examples/bookinfo/) 示例中设置的值。

1.  打开 Servicegraph UI。

    在 Kubernetes 环境中，执行以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}') 8088:8088 &
    {{< /text >}}

    在 Web 浏览器中访问 [http://localhost:8088/force/forcegraph.html](http://localhost:8088/force/forcegraph.html) , 尝试单击服务以查看服务的详细信息, 实时交通数据显示在下面的面板中。

    结果将类似于：

    {{< image width="75%" ratio="107.7%"
    link="/docs/tasks/telemetry/servicegraph/servicegraph-example.png"
    caption="Servicegraph 示例"
    >}}

1.  试验查询参数

    在Web浏览器中访问[http://localhost:8088/force/forcegraph.html?time_horizon=15s&filter_empty=true](http://localhost:8088/force/forcegraph.html?time_horizon=15s&filter_empty=true), 请注意提供的查询参数。

    `filter_empty=true` 将仅显示当前在时间范围内接收流量的服务。

    `time_horizon=15s` 影响上面的过滤器，并且还会在单击服务时影响报告的流量信息, 交通信息将在指定的时间范围内汇总。

    默认行为是不过滤空服务，并使用5分钟的时间范围。

### 关于 Servicegraph 附加组件

[Servicegraph]({{< github_tree >}}/addons/servicegraph) 服务提供端点，用于生成和可视化网格内的服务图, 它公开了以下端点：

* `/force/forcegraph.html` 如上所述，这是一个交互式[D3.js](https://d3js.org/) 可视化。

* `/dotviz` 是一个静态的[Graphviz](https://graphviz.gitlab.io/) 可视化。

* `/dotgraph` 提供[DOT](https://en.wikipedia.org/wiki/DOT_(graph_description_language))序列化。

* `/d3graph` 为 D3 可视化提供了 JSON 序列化。

* `/graph` 提供通用的 JSON 序列化。

所有端点都采用上面探讨的查询参数。

Servicegraph 示例建立在 Prometheus 查询之上，取决于标准的 Istio 度量标准配置。

## 清理

*   在 Kubernetes 环境中，执行以下命令以删除 Servicegraph 附加组件：

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/addons/servicegraph.yaml
    {{< /text >}}

* 如果您不打算探索任何后续任务，请参阅[Bookinfo 清理](/zh/docs/examples/bookinfo/#清理) 说明以关闭应用程序。
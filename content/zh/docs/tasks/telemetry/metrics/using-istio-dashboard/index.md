---
title: 使用 Grafana 可视化指标度量
description: 这个任务向您展示了如何设置和使用 Istio 仪表盘来监视网格流量。
weight: 40
keywords: [telemetry,visualization]
---

本任务向您展示如何设置和使用 Istio 仪表盘来监控网格流量。
作为此任务的一部分，您将使用 Grafana Istio 附加组件和基于 Web 的界面来查看服务网格流量数据。

[Bookinfo](/zh/docs/examples/bookinfo/) 示例应用程序在整个任务中被用作示例应用程序。

## 在您开始之前

* 在您的集群中 [安装 Istio](/zh/docs/setup)。如果您使用 Helm 安装，请通过 `--set grafana.enabled=true` [选项](/zh/docs/reference/config/installation-options/)启用 Grafana 组件。
* 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 应用。

## 查看 Istio 仪表盘

1.  确认您的群集中 `prometheus` 服务正在运行。

    在 Kubernetes 环境中，执行以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get svc prometheus
    NAME         CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
    prometheus   10.59.241.54   <none>        9090/TCP   2m
    {{< /text >}}

1.  验证 Grafana 服务是否在群集中运行。

    在 Kubernetes 环境中，执行以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get svc grafana
    NAME      CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    grafana   10.59.247.103   <none>        3000/TCP   2m
    {{< /text >}}

1.  通过 Grafana UI 打开 Istio 仪表盘。

    在 Kubernetes 环境中，执行以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &
    {{< /text >}}

    在 Web 浏览器中访问 [http://localhost:3000/dashboard/db/istio-mesh-dashboard](http://localhost:3000/dashboard/db/istio-mesh-dashboard)。

    Istio 仪表盘看起来类似于：

    {{< image link="grafana-istio-dashboard.png" caption="Istio Dashboard" >}}

1.  向网格发送流量。

    对于 Bookinfo 示例，请在 Web 浏览器中访问 `http://$GATEWAY_URL/productpage` 或发出以下命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

    {{< tip >}}
    `$GATEWAY_URL` 在 [Bookinfo](/docs/examples/bookinfo/) 例子中被设置。
    {{< /tip >}}

    刷新几次页面（或发送几次命令）以产生少量流量。

    再次查看 Istio 仪表盘，它应该显示出生成的流量，看起来类似于：

    {{< image link="dashboard-with-traffic.png" caption="Istio Dashboard With Traffic" >}}

    这提供了网格的全局视图以及网格中的服务和工作负载。
    您可以通过导航到特定仪表盘获得有关服务和工作负载的更多详细信息，如下所述。

1.  可视化服务仪表盘。

    从 Grafana 仪表盘的左上角导航菜单，您可以导航到 Istio 服务仪表盘或使用浏览器直接访问 [http://localhost:3000/dashboard/db/istio-service-dashboard](http://localhost:3000/dashboard/db/istio-service-dashboard)。

    Istio 服务仪表盘看起来类似于：

    {{< image link="istio-service-dashboard.png" caption="Istio Service Dashboard" >}}

    这提供了有关服务的指标的详细信息，进一步地提供了有关该服务的客户端工作负载（调用此服务的工作负载）和服务工作负载（提供此服务的工作负载）的详细信息。

1.  可视化工作负载仪表盘。

    从 Grafana 仪表盘的左上角导航菜单，您可以导航到 Istio 工作负载仪表盘或使用浏览器直接访问 [http://localhost:3000/dashboard/db/istio-workload-dashboard](http://localhost:3000/dashboard/db/istio-workload-dashboard)。

    Istio 工作负载仪表盘看起来类似于：

    {{< image link="istio-workload-dashboard.png" caption="Istio Workload Dashboard" >}}

    这会提供有关每个工作负载的指标的详细信息，进一步地提供有关该工作负载的入站工作负载（向此工作负载发送请求的工作负载）和出站服务（此工作负载发送请求的服务）的指标。

### 关于 Grafana 插件

Grafana 附加组件是 Grafana 的预配置实例。
基础镜像（[`grafana/grafana:5.2.3`](https://hub.docker.com/r/grafana/grafana/)）已修改为同时启动 Prometheus 数据源和 Istio 仪表盘。
Istio 的基本安装文件，特别是 Mixer，附带了全局（用于每个服务）指标的默认配置。
Istio 仪表盘被构建为与默认 Istio 度量配置和 Prometheus 后端一起使用。

Istio 仪表盘由三个主要部分组成：

1.  网格摘要视图。此部分提供网格的全局摘要视图，并在网格中显示 HTTP/gRPC 和 TCP 工作负载。

1.  单个服务视图。此部分提供有关网格中每个服务（HTTP/gRPC 和 TCP）的请求和响应的度量标准，同时还提供了有关此服务的客户端和服务工作负载的指标。

1.  单个工作负载视图。此部分提供有关网格内每个工作负载（HTTP/gRPC 和 TCP）的请求和响应的指标，同时还提供了有关此工作负载的入站工作负载和出站服务的指标。

有关如何创建、配置和编辑仪表盘的更多信息，请参阅 [Grafana 文档](https://docs.grafana.org/)。

## 清理

*   删除任何可能正在运行的 `kubectl port-forward` 进程：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

*   如果您不打算探索任何后续任务，请参考 [Bookinfo 清理](/docs/examples/bookinfo/#cleanup)说明关闭应用程序。

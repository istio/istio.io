---
title: 使用 Grafana 进行指标可视化
description: 此任务说明如何设置和使用 Istio 仪表板来监视网格流量。
weight: 40
keywords: [telemetry,visualization]
---

此任务说明如何设置和使用 Istio 仪表板来监视网格流量, 作为此任务的一部分，您将需要安装 Grafana Istio 附加组件，并使用基于 Web 的界面查看服务网格中的流量数据。

[Bookinfo](/zh/docs/examples/bookinfo/) 示例应用程序在整个任务中用作示例应用程序。

## 开始之前

* 在集群中[安装 Istio](/zh/docs/setup/)。如果使用 Helm 方式进行安装，可以使用 `--set grafana.enabled=true` [开关](/zh/docs/reference/config/installation-options/)来启用 Grafana 插件。

* 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 应用。

## 查看 Istio 仪表板

1. 验证 `prometheus` 服务是否在集群中正常运行。

    如果是 Kubernetes 环境中，可以使用如下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get svc prometheus
    NAME         CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
    prometheus   10.59.241.54   <none>        9090/TCP   2m
    {{< /text >}}

1. 验证 `grafana` 服务是否在集群中正常运行。

    如果是 Kubernetes 环境中，可以使用如下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get svc grafana
    NAME      CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    grafana   10.59.247.103   <none>        3000/TCP   2m
    {{< /text >}}

1. 打开 Grafana 界面中的 Istio Dashboard：

    如果是在 Kubernetes 环境中，请执行如下命令：

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &
    {{< /text >}}

    用浏览器浏览 [http://localhost:3000/dashboard/db/istio-mesh-dashboard](http://localhost:3000/dashboard/db/istio-mesh-dashboard)。

    Istio Dashboard 大致会显示如下内容：

    {{< image link="./grafana-istio-dashboard.png" caption="Istio Dashboard" >}}

1. 向网格中发送流量。

    对于 Bookinfo 实例来说，有两种方式产生流量：用浏览器打开网址 `http://$GATEWAY_URL/productpage`；或者执行下面的命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

    {{< tip >}}
    `$GATEWAY_URL` 变量的定义来自于 [Bookinfo](/zh/docs/examples/bookinfo/) 示例。
    {{< /tip >}}

    刷新页面几次（或者执行几次命令），就会生成一些流量了。

    再次打开 Istio Dashboard，会看到其中显示了刚刚生成的流量，大致如图所示：

    {{< image link="./dashboard-with-traffic.png" caption="Istio Dashboard" >}}

    这里给出的是全网格范围内服务和工作负载的概况。可以浏览每个服务或工作负载，来获取特定目标的 Dashboard。下面会进行简单的介绍。

1. 可视化的服务 Dashboard。

    从 Grafana Dashboard 左侧的导航菜单中打开 Istio Service Dashboard，也可以直接使用浏览器打开 [http://localhost:3000/dashboard/db/istio-service-dashboard](http://localhost:3000/dashboard/db/istio-service-dashboard)。

    Istio 的服务 Dashboard 大致如图所示：

    {{< image link="./istio-service-dashboard.png" caption="Istio 服务 Dashboard" >}}

    这里给出了指定服务的详细指标，还有该服务的客户端工作负载（正在调用这一服务的工作负载）以及服务端工作负载（提供服务的工作负载）。

1. 可视化的工作负载 Dashboard。

    从 Grafana Dashboard 左侧的导航菜单中打开 Istio 工作负载 Dashboard，或者用浏览器打开 [http://localhost:3000/dashboard/db/istio-workload-dashboard](http://localhost:3000/dashboard/db/istio-workload-dashboard)。

    Istio 工作负载 Dashboard 大致如图所示：

    {{< image link="./istio-workload-dashboard.png" caption="Istio 工作负载 Dashboard" >}}

    这里展示了每个工作负载的指标数据，还有相关的入站工作负载（向本工作负载发送请求的工作负载）以及该工作负载请求的服务。

### 关于 Grafana 插件

Grafana 插件是一个预配置的 Grafana 实例。基于基础镜像（[`grafana/grafana:5.2.3`](https://hub.docker.com/r/grafana/grafana/)）进行了修改，加入了 Prometheus 数据源以及 Istio Dashboard。Istio 和 Mixer 初始化了缺省的全局（用于每个服务）指标。Istio Dashboard 连接了 Prometheus 后端以及缺省的 Istio 指标配置。

Istio Dashboard 包含三个主要部分：

1. Mesh Summary View，提供了网格范围内的全局概要视图，其中还包含了网格中的 HTTP/gRPC 以及 TCP 工作负载。

1. 独立的服务视图，其中包含了网格之中各个服务的请求和响应（HTTP/gRPC 以及 TCP）的指标数据。其中还有当前服务的上下游工作负载的指标。

1. 独立的工作负载视图，这里包含了网格中每个工作负载的请求和响应（HTTP/gRPC 以及 TCP）的指标数据，另外还包含了入站工作负载以及出站服务的相关指标。

要了解如何创建、配置和编辑 Dashboard，可移步浏览 [Grafana 文档](https://docs.grafana.org/)。

## 清理

* 停止运行中的 `kubectl port-forward` 进程：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* 如果不想继续进行后续任务，参照[清理 Bookinfo](/zh/docs/examples/bookinfo/#清理)的步骤关闭示例应用。

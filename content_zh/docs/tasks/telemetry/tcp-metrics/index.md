---
title: 获取 TCP 服务指标
description: 本任务展示了如何配置 Istio 进行 TCP 服务的指标收集。
weight: 25
keywords: [telemetry,metrics,tcp]
---

本文任务展示了如何对 Istio 进行配置，从而自动收集网格中 TCP 服务的遥测数据。在任务最后，会为网格中的一个 TCP 服务启用一个新的指标。

在本例中会使用 [Bookinfo](/docs/examples/bookinfo/) 作为示例应用。

## 开始之前

* 在集群中[安装 Istio](/docs/setup/) 并部署一个应用。

* 任务中假设 Bookinfo 应用部署在 `default` 命名空间中。如果使用不同的命名空间，需要更新例子中的相关配置和命令。

## 收集新的遥测数据

1. 创建一个新的 YAML 文件用于配置新的指标，Istio 会据此文件生成并自动收集新建指标。

    把下面的文本保存为 `tcp_telemetry.yaml`：

    {{< text yaml >}}
    # 配置一个指标，描述从服务器发送到客户端的字节数量
    apiVersion: "config.istio.io/v1alpha2"
    kind: metric
    metadata:
      name: mongosentbytes
      namespace: default
    spec:
      value: connection.sent.bytes | 0 # uses a TCP-specific attribute
      dimensions:
        source_service: source.service | "unknown"
        source_version: source.labels["version"] | "unknown"
        destination_version: destination.labels["version"] | "unknown"
      monitoredResourceType: '"UNSPECIFIED"'
    ---
    # 这一指标代表从客户端到服务器的字节数
    apiVersion: "config.istio.io/v1alpha2"
    kind: metric
    metadata:
      name: mongoreceivedbytes
      namespace: default
    spec:
      value: connection.received.bytes | 0 # uses a TCP-specific attribute
      dimensions:
        source_service: source.service | "unknown"
        source_version: source.labels["version"] | "unknown"
        destination_version: destination.labels["version"] | "unknown"
      monitoredResourceType: '"UNSPECIFIED"'
    ---
    # 配置 Prometheus 的 Handler
    apiVersion: "config.istio.io/v1alpha2"
    kind: prometheus
    metadata:
      name: mongohandler
      namespace: default
    spec:
      metrics:
      - name: mongo_sent_bytes # Prometheus metric name
        instance_name: mongosentbytes.metric.default # Mixer instance name (fully-qualified)
        kind: COUNTER
        label_names:
        - source_service
        - source_version
        - destination_version
      - name: mongo_received_bytes # Prometheus metric name
        instance_name: mongoreceivedbytes.metric.default # Mixer instance name (fully-qualified)
        kind: COUNTER
        label_names:
        - source_service
        - source_version
        - destination_version
    ---
    # 这里定义一个 rule，把 metric 发送给 Prometheus handler
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: mongoprom
      namespace: default
    spec:
      match: context.protocol == "tcp"
             && destination.service == "mongodb.default.svc.cluster.local"
      actions:
      - handler: mongohandler.prometheus
        instances:
        - mongoreceivedbytes.metric
        - mongosentbytes.metric
    {{< /text >}}

1. 应用新配置。

    {{< text bash >}}
    $ istioctl create -f tcp_telemetry.yaml
    Created config metric/default/mongosentbytes at revision 3852843
    Created config metric/default/mongoreceivedbytes at revision 3852844
    Created config prometheus/default/mongohandler at revision 3852845
    Created config rule/default/mongoprom at revision 3852846
    {{< /text >}}

1. 设置 Bookinfo 使用 Mongodb。

    1. 安装 `ratings` 服务的 `v2` 版本。

        如果使用的是启用了 Sidecar 自动注入的集群，可以简单使用 `kubectl` 进行服务部署：

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
        {{< /text >}}

        如果使用手工的 Sidecar 注入方式，就需要使用下面的命令：

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@)
        deployment "ratings-v2" configured
        {{< /text >}}

    1. 安装 `mongodb` 服务：

        如果使用的是启用了 Sidecar 自动注入的集群，可以简单使用 `kubectl` 进行服务部署：

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@
        {{< /text >}}

        如果使用手工的 Sidecar 注入方式，就需要使用下面的命令：

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@)
        service "mongodb" configured
        deployment "mongodb-v1" configured
        {{< /text >}}

    1. 创建 `ratings` 以及 `reviews` 两个虚拟服务:

        {{< text bash >}}
        $ istioctl create -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
        Created config virtual-service/default/reviews at revision 3003
        Created config virtual-service/default/ratings at revision 3004
        {{< /text >}}

    1. 新增路由规则，将流量发送到 `ratings:v2` 之中：

        {{< text bash >}}
        $ istioctl create -f @samples/bookinfo/networking/destination-rule-all.yaml@
        destinationrule.networking.istio.io/productpage created
        destinationrule.networking.istio.io/reviews created
        destinationrule.networking.istio.io/ratings created
        destinationrule.networking.istio.io/details created
        {{< /text >}}

1. 向应用发送流量。

    对于 Bookinfo 应用来说，在浏览器中浏览 `http://$GATEWAY_URL/productpage`，或者使用下面的命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1. 检查是否已经生成并收集了新的指标。

    在 Kubernetes 环境中，使用下面的命令为 Prometheus 设置端口转发：

    {{< text bash >}}
    $ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
    {{< /text >}}

    使用 [Prometheus 界面](http://localhost:9090/graph#%5B%7B%22range_input%22%3A%221h%22%2C%22expr%22%3A%22istio_mongo_received_bytes%22%2C%22tab%22%3A1%7D%5D) 浏览新的指标值。

    上面的连接会打开 Promethe 界面，并执行了对 `istio_mongo_received_bytes` 指标的查询。**Console** 标签页中包含了大致如下的内容：

    {{< text plain >}}
    istio_mongo_received_bytes{destination_version="v1",instance="istio-mixer.istio-system:42422",job="istio-mesh",source_service="ratings.default.svc.cluster.local",source_version="v2"} 2317
    {{< /text >}}

    > Istio 还会针对 MongoDB 收集协议特定的统计数据。例如来自 `ratings` 服务的 OP_QUERY 总数，同样可以使用[类似查询](http://localhost:9090/graph#%5B%7B%22range_input%22%3A%221h%22%2C%22expr%22%3A%22envoy_mongo_mongo_collection_ratings_query_total%22%2C%22tab%22%3A1%7D%5D)获知。

## 理解 TCP 遥控数据的收集过程

这一任务中，我们加入了一段 Istio 配置，对于所有目标为网格内 TCP 服务的流量，Mixer 自动为其生成并报告新的指标。

类似[收集指标和日志任务](/docs/tasks/telemetry/metrics-logs/)中的情况，新的配置由 _instance_ 、一个 _handler_ 以及一个 _rule_ 构成。请参看该任务来获取关于指标收集的组件的完整信息。

_instances_ 中属性集的可选范围不同，是 TCP 服务的指标收集过程的唯一差异。

### TCP 属性

TCP 相关的属性是 Istio 中 TCP 策略和控制的基础。这些属性是由服务端的 Envoy 代理生成的。它们在连接建立时发给 Mixer，在连接的存活期间周期性的进行发送（周期性报告），最后在连接关闭时再次发送（最终报告）。周期性报告的缺省间隔时间为 10 秒钟，最小取值为 1 秒。另外上下文属性让策略有了区分 `http` 和 `tcp` 协议的能力。

{{< image width="100%" ratio="192.50%"
    link="/docs/tasks/telemetry/tcp-metrics/istio-tcp-attribute-flow.svg"
    alt="Istio 服务网格中的 TCP 服务属性生成流程"
    caption="TCP 属性流程"
    >}}

## 清理

* 删除新的遥测配置：

    {{< text bash >}}
    $ istioctl delete -f tcp_telemetry.yaml
    {{< /text >}}

* 删除端口转发进程：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* 如果不准备进一步探索其他任务，请参照 [Bookinfo 清理](/docs/examples/bookinfo/#cleanup)，关闭示例应用。

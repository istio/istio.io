---
title: 收集 TCP 服务指标
description: 本任务展示了如何配置 Istio 进行 TCP 服务的指标收集。
weight: 20
keywords: [telemetry,metrics,tcp]
aliases:
    - /zh/docs/tasks/telemetry/tcp-metrics
    - /zh/docs/tasks/telemetry/metrics/tcp-metrics/
---

本文任务展示了如何对 Istio 进行配置，从而自动收集网格中 TCP 服务的遥测数据。在任务最后，会为网格中的一个 TCP 服务启用一个新的指标。

在本例中会使用 [Bookinfo](/zh/docs/examples/bookinfo/) 作为示例应用。

## 开始之前{#before-you-begin}

* 在集群中[安装 Istio](/zh/docs/setup/) 并部署一个应用。

* 任务中假设 Bookinfo 应用部署在 `default` 命名空间中。如果使用不同的命名空间，需要更新例子中的相关配置和命令。

## 收集新的遥测数据{#collecting-new-telemetry-data}

1. 创建一个新的 YAML 文件用于配置新的指标，Istio 会据此文件生成并自动收集新建指标。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/tcp-metrics.yaml@
    {{< /text >}}

    {{< warning >}}
    如果您使用的是 Istio 1.1.2 或更低版本，请改用以下配置：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/telemetry/tcp-metrics-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

1.  设置 Bookinfo 使用 Mongodb。

    1.  安装 `ratings` 服务的 `v2` 版本。

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

    1.  Bookinfo 示例部署了每个微服务的多个版本，因此您将首先创建目标规则定义每个版本对应的服务子集，以及每个子集的负载均衡策略。

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
        {{< /text >}}

        如果您启用了双向 TLS，请执行以下操作

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
        {{< /text >}}

        您可以使用以下命令显示目标规则：

        {{< text bash >}}
        $ kubectl get destinationrules -o yaml
        {{< /text >}}

        由于虚拟服务中的子集引用依赖于目标规则，
        在添加引用这些子集的虚拟服务之前，请等待几秒钟以使目标规则传播。

    1. 创建 `ratings` 以及 `reviews` 两个虚拟服务：

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
        Created config virtual-service/default/reviews at revision 3003
        Created config virtual-service/default/ratings at revision 3004
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
    istio_mongo_received_bytes{destination_version="v1",instance="172.17.0.18:42422",job="istio-mesh",source_service="ratings-v2",source_version="v2"}
    {{< /text >}}

## 理解 TCP 遥测数据的收集过程{#understanding-tcp-telemetry-collection}

这一任务中，我们加入了一段 Istio 配置，对于所有目标为网格内 TCP 服务的流量，Mixer 自动为其生成并报告新的指标。

类似[收集指标和日志任务](/zh/docs/tasks/observability/metrics/collecting-metrics/)中的情况，新的配置由 _instance_、一个 _handler_ 以及一个 _rule_ 构成。请参看该任务来获取关于指标收集的组件的完整信息。

_instances_ 中属性集的可选范围不同，是 TCP 服务的指标收集过程的唯一差异。

### TCP 属性{#tcp-attributes}

TCP 相关的属性是 Istio 中 TCP 策略和控制的基础。这些属性是由服务端的 Envoy 代理生成的。它们在连接建立时发给 Mixer，在连接的存活期间周期性的进行发送（周期性报告），最后在连接关闭时再次发送（最终报告）。周期性报告的缺省间隔时间为 10 秒钟，最小取值为 1 秒。另外上下文属性让策略有了区分 `http` 和 `tcp` 协议的能力。

{{< image link="./istio-tcp-attribute-flow.svg"
    alt="Istio 服务网格中的 TCP 服务属性生成流程"
    caption="TCP 属性流程"
    >}}

## 清除{#cleanup}

*   删除新的遥测配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/tcp-metrics.yaml@
    {{< /text >}}

    如果您使用的是 Istio 1.1.2 或更低版本：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/telemetry/tcp-metrics-crd.yaml@
    {{< /text >}}

*   删除 `port-forward` 进程：

    {{< text bash >}}
    $ killall kubectl
    {{< /text >}}

* 如果不准备进一步探索其他任务，请参照 [Bookinfo 清除](/zh/docs/examples/bookinfo/#cleanup)，关闭示例应用。

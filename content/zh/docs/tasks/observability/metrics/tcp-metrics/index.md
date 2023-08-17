---
title: 收集 TCP 服务指标
description: 本任务展示了如何配置 Istio 进行 TCP 服务的指标收集。
weight: 20
keywords: [telemetry,metrics,tcp]
aliases:
    - /zh/docs/tasks/telemetry/tcp-metrics
    - /zh/docs/tasks/telemetry/metrics/tcp-metrics/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

本文任务展示了如何对 Istio 进行配置，从而自动收集网格中 TCP 服务的遥测数据。
在任务最后，会为网格中的一个 TCP 服务启用一个新的指标。

在本例中会使用 [Bookinfo](/zh/docs/examples/bookinfo/) 作为示例应用。

## 开始之前  {#before-you-begin}

* 在集群中[安装 Istio](/zh/docs/setup/) 并部署一个应用。您必须安装
  [Prometheus](/zh/docs/ops/integrations/prometheus/)。

* 任务中假设 Bookinfo 应用部署在 `default` 命名空间中。如果使用不同的命名空间，
  需要更新例子中的相关配置和命令。

## 收集新的遥测数据  {#collecting-new-telemetry-data}

1. 设置 Bookinfo 使用 MongoDB。

    1. 安装 `ratings` 服务的 `v2` 版本。

        如果使用的是启用了 Sidecar 自动注入的集群，可以使用 `kubectl` 进行服务部署：

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
        serviceaccount/bookinfo-ratings-v2 created
        deployment.apps/ratings-v2 created
        {{< /text >}}

        如果使用手工的 Sidecar 注入方式，就需要使用下面的命令：

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@)
        deployment "ratings-v2" configured
        {{< /text >}}

    1. 安装 `mongodb` 服务：

        如果使用的是启用了 Sidecar 自动注入的集群，可以使用 `kubectl` 进行服务部署：

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@
        service/mongodb created
        deployment.apps/mongodb-v1 created
        {{< /text >}}

        如果使用手工的 Sidecar 注入方式，就需要使用下面的命令：

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@)
        service "mongodb" configured
        deployment "mongodb-v1" configured
        {{< /text >}}

    1. Bookinfo 示例部署了每个微服务的多个版本，因此您将首先创建目标规则定义每个版本对应的服务子集，
       以及每个子集的负载均衡策略。

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
        {{< /text >}}

        如果您启用了双向 TLS，请执行以下操作：

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
        virtualservice.networking.istio.io/reviews created
        virtualservice.networking.istio.io/ratings created
        {{< /text >}}

1. 向应用发送流量。

    对于 Bookinfo 应用来说，在浏览器中浏览 `http://$GATEWAY_URL/productpage`，
    或者使用下面的命令：

    {{< text bash >}}
    $ curl http://"$GATEWAY_URL/productpage"
    {{< /text >}}

    {{< tip >}}
    `$GATEWAY_URL` 是在 [Bookinfo](/zh/docs/examples/bookinfo/) 示例中设置的值。
    {{< /tip >}}

1. 检查是否已经生成并收集了 TCP 指标。

    在 Kubernetes 环境中，使用下面的命令为 Prometheus 设置端口转发：

    {{< text bash >}}
    $ istioctl dashboard prometheus
    {{< /text >}}

    在 Prometheus 浏览器窗口查看 TCP 指标的值。选择 **Graph**。
    输入 `istio_tcp_connections_opened_total` 指标或 `istio_tcp_connections_closed_total`
    并选择 **Execute**。在 **Console** 标签页中显示的表格包含了类似如下的内容：

    {{< text plain >}}
    istio_tcp_connections_opened_total{
    destination_version="v1",
    instance="172.17.0.18:42422",
    job="istio-mesh",
    canonical_service_name="ratings-v2",
    canonical_service_revision="v2"}
    {{< /text >}}

    {{< text plain >}}
    istio_tcp_connections_closed_total{
    destination_version="v1",
    instance="172.17.0.18:42422",
    job="istio-mesh",
    canonical_service_name="ratings-v2",
    canonical_service_revision="v2"}
    {{< /text >}}

## 理解 TCP 遥测数据的收集过程  {#understanding-tcp-telemetry-collection}

在此任务中，您使用 Istio 配置自动生成并报告网格内 TCP 服务的所有流量的指标。
默认情况下，所有活动连接的 TCP 指标每 `15s` 记录一次，并且此计时器可通过
`tcpReportingDuration` 进行配置。连接结束时也会记录连接的指标。

### TCP 属性  {#tcp-attributes}

几个特定于 TCP 的属性可在 Istio 中启用 TCP 策略和控制。这些属性由 Envoy
代理生成，并使用 Envoy 的 Node Metadata 从 Istio 获得。Envoy 使用基于
ALPN 的隧道和基于前缀的协议将节点元数据转发给对等 Envoy。我们定义了一个新的协议
`istio-peer-exchange`，该协议定义了网格中的客户端和 Sidecar 服务器的通告和优先级。
对于启用了 Istio 之间的连接，ALPN 协商将协议解析为 `istio-peer-exchange` 代理，
不再启用 Istio 的代理和任何其他代理。该协议扩展了 TCP，如下所示：

1. TCP 客户端，作为第一个字节序列，发送一个魔术字节串和一个长度带前缀的有效载荷。
1. TCP 服务端，作为第一个字节序列，发送一个魔术字节串和一个长度带前缀的有效载荷，
   这些有效载荷是 protobuf 编码的序列化元数据。
1. 客户端和服务器可以同时写入并且顺序混乱。Envoy 中的扩展筛选器会在下游和上游进行处理，
   直到魔术字节序列不匹配或读取了整个有效负载。

{{< image link="./alpn-based-tunneling-protocol.svg"
    alt="Istio 服务网格中的 TCP 服务属性生成流程"
    caption="TCP 属性流程"
    >}}

## 清理 {#cleanup}

*   删除 `port-forward` 进程：

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

* 如果不准备进一步探索其他任务，请参照 [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup)，关闭示例应用。

---
title: "Istio Ambient Waypoint Proxy 让一切变得简单"
description: 为简化和可扩展性引入全新的面向目的地的 Waypoint Proxy。
publishdate: 2023-03-31
attribution: "Lin Sun (Solo.io), John Howard (Google)"
keywords: [istio,ambient,waypoint]
---

Ambient 将 Istio 的功能分为两个不同的层，一个具备安全机制的 Overlay 层和一个 L7 处理层。Waypoint Proxy 是一个基于 Envoy 的可选组件，为其管理的工作负载进行 L7 处理。自 2022 年[首次发布 Ambient](/zh/blog/2022/introducing-ambient-mesh/) 以来，我们在简化 Waypoint 配置、可调试性和可扩展性方面做了许多重大变更。

## Waypoint Proxy 的架构{#architecture-of-waypoint-proxies}

与 Sidecar 类似，Waypoint Proxy 也是基于 Envoy 的，由 Istio 动态配置以服务于您的应用程序配置。
Waypoint Proxy 的独特之处在于它按照每个命名空间（默认）或每个服务帐户来运行。
通过在应用程序 Pod 之外运行，Waypoint Proxy 可以独立于应用程序安装、升级和扩展，并降低运营成本。

{{< image width="100%"
    link="waypoint-architecture.png"
    caption="Waypoint architecture"
    >}}

Waypoint Proxy 是使用 Kubernetes Gateway 资源以声明方式部署的，也可以使用以下 `istioctl` 命令来部署：

{{< text bash >}}
$ istioctl experimental waypoint generate
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: namespace
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
{{< /text >}}

Istiod 将监控这些资源并自动为用户部署和管理相应的 Waypoint Proxy。

## 将源代理配置转移到目的地代理{#shift-source-proxy-configuration-to-destination-proxy}

在现有的 Sidecar 架构中，大多数流量整形（例如[请求路由](/zh/docs/tasks/traffic-management/request-routing/zh)或[流量转移](/zh/docs/tasks/traffic-management/traffic-shifting/)或[故障注入](/zh/docs/tasks/traffic-management/fault-injection/)）策略由源（客户端）代理实现，
而大多数安全策略由目标（服务器）代理实现。这导致了一些担忧：

* 缩放——每个源 Sidecar 都需要知道关于网格中每个其他目的地的信息。这是一个多项式缩放问题。
  更糟糕的是，如果任何目标配置发生变化，我们需要立即通知所有 Sidecar。
* 调试——因为策略执行在客户端和服务器 Sidecar 之间分开，所以在故障排除时很难理解系统的行为。
* 混合环境——如果我们的系统不是所有客户端都是网格的一部分，我们就会得到不一致的行为。
  例如，非网格客户端不会遵守金丝雀部署策略，从而导致意外的流量分配。
* 所有权和归属——理想情况下，在一个命名空间中编写的策略应该只影响在同一命名空间中运行的代理所做的工作。
  然而，在这个模型中，它是由每个 Sidecar 分发和执行的。尽管 Istio 已围绕此约束进行设计以确保其安全，但它仍然不是最佳选择。

在 Ambient 中，所有策略都由目的地 Waypoint 强制执行。在许多方面，Waypoint 充当进入命名空间（默认范围）或服务帐户的网关。
Istio 强制所有进入命名空间的流量都经过 Waypoint ，然后该 Waypoint 执行该命名空间的所有策略。因此，每个 Waypoint 只需要了解其自己命名空间的配置。

特别是可扩展性问题，对于在大型集群中运行的用户来说是一个困扰。如果我们把它形象化，我们就可以看到新架构有多大的改进。

考虑一个简单的部署，我们有 2 个命名空间，每个命名空间有 2 个（彩色编码的）部署。
为 Sidecar 编程所需的 Envoy (XDS) 配置显示为圆圈：

{{< image width="70%"
    link="sidecar-config.png"
    caption="Every sidecar has configuration about all other sidecars"
    >}}

在 Sidecar 模型中，我们有 4 个工作负载，每个工作负载有 4 组配置。
如果这些配置中的任何一个发生更改，则所有这些配置都需要更新。总共有 16 个配置分布。

然而，在 Waypoint 架构中，配置得到了极大的简化：

{{< image width="70%"
    link="waypoint-config.png"
    caption="Each waypoint only has configuration for its own namespace"
    >}}

在这里，我们看到一个非常不同的情况。我们只有 2 个 Waypoint Proxy ，
因为每个 Waypoint Proxy 都能为整个命名空间提供服务，而且每个 Waypoint Proxy 只需要为自己的命名空间配置。
总的来说，我们有 25% 的配置发送量，即使是一个简单的例子。

如果我们将每个命名空间扩大到 25 个部署，每个部署有 10 个 Pod，每个航点部署有 2 个 Pod，以实现高可用性，那么数字就更加惊人了 -- Waypoint 的配置发送量只需要挎包的 0.8%，如下表所示

| 配置分发    |         命名空间 1              |       命名空间 2                |     总计     |
| --------------------------- | -------------------------------- | -------------------------------- | ------------- |
| Sidecars                    | 25 configurations * 250 sidecars | 25 configurations * 250 sidecars |    12500      |
| Waypoints                   | 25 configurations * 2 waypoints  | 25 configurations * 2 waypoints  |     100       |
| Waypoints / Sidecars        |              0.8%                |               0.8%               |      0.8%     |

虽然我们使用命名空间范围的 Waypoint Proxy 来说明上面的简化，
但当您将其应用于服务帐户 Waypoint Proxy 时，简化是相似的。

这样减少配置意味着控制平面和数据平面更低的资源使用率（CPU、RAM 和网络带宽）。
虽然如今的用户可以通过在 Istio 网络资源或 [Sidecar](/zh/docs/reference/config/networking/sidecar/) API 中谨慎使用 `exportTo` 来看到类似的改进，但在 Ambient 模式下不再需要这样做，这就使得扩缩容轻而易举。

## 如果我的目的地没有 Waypoint Proxy 怎么办？{#what-if-my-destination-doesn’t-have-waypoint-proxy}

Ambient 模式的设计围绕这样一个假设，即大多数配置最好由服务生产者而不是服务消费者实施。
然而，情况并非总是如此 —— 有时我们需要为我们无法控制的目的地配置流量管理。
一个常见的例子是连接到具有改进弹性的外部服务，以处理偶尔的连接问题（例如，为调用添加超时example.com）。

这是社区中正在积极开发的一个领域，我们在其中设计如何将流量路由到您的出口网关，以及您如何使用所需的策略配置出口网关。留意这方面的未来博客文章！

## 对 Waypoint 配置的深入研究{#a-deep-dive-of-waypoint-configuration}

假设您已遵循 [Ambient 入门指南](http://preliminary.istio.io/latest/docs/ops/ambient/getting-started/)直至并包括[控制流量部分](http://preliminary.istio.io/latest/docs/ops/ambient/getting-started/#control)，您已经为 bookinfo-reviews 服务帐户部署了一个 Waypoint Proxy，以将 90% 的流量引导至 review v1，将 10% 的流量引导至 review v2。

使用 `istioctl` 检索 `reviews` Waypoint Proxy 的侦听器：

{{< text bash >}}
$ istioctl proxy-config listener deploy/bookinfo-reviews-istio-waypoint --waypoint
LISTENER              CHAIN                                                 MATCH                                         DESTINATION
envoy://connect_originate                                                       ALL                                           Cluster: connect_originate
envoy://main_internal inbound-vip|9080||reviews.default.svc.cluster.local-http  ip=10.96.104.108 -> port=9080                 Inline Route: /*
envoy://main_internal direct-tcp                                            ip=10.244.2.14 -> ANY                         Cluster: encap
envoy://main_internal direct-tcp                                            ip=10.244.1.6 -> ANY                          Cluster: encap
envoy://main_internal direct-tcp                                            ip=10.244.2.11 -> ANY                         Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.2.11 -> application-protocol='h2c'  Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.2.11 -> application-protocol='http/1.1' Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.2.14 -> application-protocol='http/1.1' Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.2.14 -> application-protocol='h2c'  Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.1.6 -> application-protocol='h2c'   Cluster: encap
envoy://main_internal direct-http                                           ip=10.244.1.6 -> application-protocol='http/1.1'  Cluster: encap
envoy://connect_terminate default                                               ALL                                           Inline Route:
{{< /text >}}

对于到达端口的请求 `15008`，默认情况下是 Istio 的入站 {{< gloss >}}HBONE{{< /gloss >}} 端口，Waypoint Proxy 终止 HBONE 连接并将请求转发给侦听器以执行任何工作负载策略，`main_internal` 例如作为授权策略。
如果您不熟悉[内部侦听器](https://www.envoyproxy.io/docs/envoy/latest/configuration/other_features/internal_listener)，它们是 Envoy 侦听器，无需使用系统网络 API 即可接受用户空间连接。`--waypoint` 上面添加到命令的标志指示 `istioctl proxy-config` 它显示 `main_internal` 侦听器的详细信息、它的过滤器链、链匹配和目的地。

注意 `10.96.104.108` 是评论的服务 VIP，`10.244.x.x` 是评论的 v1/v2/v3 Pod IP，
您可以使用命令查看您的集群 `kubectl get svc,pod -o wide`。
对于纯文本或 HBONE 终止的入站流量，它将在服务 VIP 和端口 9080 上进行匹配以供审查或通过 Pod IP 地址和应用程序协议（ `ANY`、`h2c`、`http/1.1` 进行匹配。

检查 Waypoint Proxy 的集群 `reviews`，您将获得 `main_internal` 集群以及一些入站集群。
除了用于基础设施的集群之外，唯一创建的 Envoy 集群是为在同一服务帐户中运行的服务和 Pod 创建的。没有为在别处运行的服务或 Pod 创建集群。

{{< text bash >}}
$ istioctl proxy-config clusters deploy/bookinfo-reviews-istio-waypoint
SERVICE FQDN                         PORT SUBSET  DIRECTION   TYPE         DESTINATION RULE
agent                                -    -       -           STATIC
connect_originate                    -    -       -           ORIGINAL_DST
encap                                -    -       -           STATIC
kubernetes.default.svc.cluster.local 443  tcp     inbound-vip EDS
main_internal                        -    -       -           STATIC
prometheus_stats                     -    -       -           STATIC
reviews.default.svc.cluster.local    9080 http    inbound-vip EDS
reviews.default.svc.cluster.local    9080 http/v1 inbound-vip EDS
reviews.default.svc.cluster.local    9080 http/v2 inbound-vip EDS
reviews.default.svc.cluster.local    9080 http/v3 inbound-vip EDS
sds-grpc                             -    -       -           STATIC
xds-grpc                             -    -       -           STATIC
zipkin                               -    -       -           STRICT_DNS
{{< /text >}}

请注意，列表中没有 `outbound` 集群，您可以用 `istioctl proxy-config cluster deploy/bookinfo-reviews-istio-waypoint --direction outbound` 来确认!
最棒的是，您不需要在任何其他 bookinfo 服务上配置 `exportTo`（例如，`productpage` 或 `ratings` 服务）。
换句话说，`reviews` Waypoint 不会感知到任何不必要的集群，不需要您进行任何额外的手动配置。

显示 Waypoint Proxy 的路线列表 `reviews`：

{{< text bash >}}
$ istioctl proxy-config routes deploy/bookinfo-reviews-istio-waypoint
NAME                                                    DOMAINS MATCH              VIRTUAL SERVICE
encap                                                   *       /*
inbound-vip|9080|http|reviews.default.svc.cluster.local *       /*                 reviews.default
default
{{< /text >}}

回想一下，您没有在 Istio 网络资源上配置任何 Sidecar 资源，也未执行 `exportTo` 配置。
然而，您部署了 `bookinfo-productpage` 路由来配置 Ingress 网关以路由到 `productpage`，
但 `reviews` Waypoint 还未感知到此类不相关的路由。

在显示 `inbound-vip|9080|http|reviews.default.svc.cluster.local` 路由的详情时，
您会看到基于权重的路由配置将 90% 的流量引导到 `reviews` v1，将 10% 的流量引导到 `reviews` v2，
还能看到 Istio 的一些默认重试和超时配置。如前所述，这证实了流量和弹性策略已从来源转移到面向目的地的 Waypoint。

{{< text bash >}}
$ istioctl proxy-config routes deploy/bookinfo-reviews-istio-waypoint --name "inbound-vip|9080|http|reviews.default.svc.cluster.local" -o yaml
- name: inbound-vip|9080|http|reviews.default.svc.cluster.local
 validateClusters: false
 virtualHosts:
 - domains:
   - '*'
   name: inbound|http|9080
   routes:
   - decorator:
       operation: reviews:9080/*
     match:
       prefix: /
     metadata:
       filterMetadata:
         istio:
           config: /apis/networking.istio.io/v1alpha3/namespaces/default/virtual-service/reviews
     route:
       maxGrpcTimeout: 0s
       retryPolicy:
         hostSelectionRetryMaxAttempts: "5"
         numRetries: 2
         retriableStatusCodes:
         - 503
         retryHostPredicate:
         - name: envoy.retry_host_predicates.previous_hosts
           typedConfig:
             '@type': type.googleapis.com/envoy.extensions.retry.host.previous_hosts.v3.PreviousHostsPredicate
         retryOn: connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes
       timeout: 0s
       weightedClusters:
         clusters:
         - name: inbound-vip|9080|http/v1|reviews.default.svc.cluster.local
           weight: 90
         - name: inbound-vip|9080|http/v2|reviews.default.svc.cluster.local
           weight: 10
{{< /text >}}

查看 `reviews` Waypoint Proxy 的端点：

{{< text bash >}}
$ istioctl proxy-config endpoints deploy/bookinfo-reviews-istio-waypoint
ENDPOINT                                            STATUS  OUTLIER CHECK CLUSTER
127.0.0.1:15000                                     HEALTHY OK            prometheus_stats
127.0.0.1:15020                                     HEALTHY OK            agent
envoy://connect_originate/                          HEALTHY OK            encap
envoy://connect_originate/10.244.1.6:9080           HEALTHY OK            inbound-vip|9080|http/v2|reviews.default.svc.cluster.local
envoy://connect_originate/10.244.1.6:9080           HEALTHY OK            inbound-vip|9080|http|reviews.default.svc.cluster.local
envoy://connect_originate/10.244.2.11:9080          HEALTHY OK            inbound-vip|9080|http/v1|reviews.default.svc.cluster.local
envoy://connect_originate/10.244.2.11:9080          HEALTHY OK            inbound-vip|9080|http|reviews.default.svc.cluster.local
envoy://connect_originate/10.244.2.14:9080          HEALTHY OK            inbound-vip|9080|http/v3|reviews.default.svc.cluster.local
envoy://connect_originate/10.244.2.14:9080          HEALTHY OK            inbound-vip|9080|http|reviews.default.svc.cluster.local
envoy://main_internal/                              HEALTHY OK            main_internal
unix://./etc/istio/proxy/XDS                        HEALTHY OK            xds-grpc
unix://./var/run/secrets/workload-spiffe-uds/socket HEALTHY OK            sds-grpc
{{< /text >}}

请注意，即使您在 `default` 和 `istio-system` 命名空间中还有一些其他服务，
您也不会获得除 reviews 之外与任何服务相关的任何端点。

## 结束语{#wrapping-up}

我们对专注于面向目的地的 Waypoint Proxy 的 Waypoint 简化感到非常兴奋。
这是朝着简化 Istio 的可用性、可扩展性和可调试性迈出的又一重要步骤，
这些是 Istio 路线图上的重中之重。按照我们的[入门指南](http://preliminary.istio.io/latest/docs/ops/ambient/getting-started/)立即尝试 Ambient
alpha 构建并体验简化的 Waypoint Proxy！

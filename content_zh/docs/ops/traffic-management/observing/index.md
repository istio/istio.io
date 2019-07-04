---
title: 配置问题诊断
description: 介绍一些工具和技术，用来针对流量管理方面的配置问题进行诊断。
weight: 40
keywords: [debug,proxy,status,config,pilot,envoy]
---

Istio 提供了两个非常有价值的命令，用于协助对流量管理方面的配置问题进行诊断：[`proxy-status`](/docs/reference/commands/istioctl/#istioctl-proxy-status) 和 [`proxy-config`](/docs/reference/commands/istioctl/#istioctl-proxy-config)。

`proxy-status` 命令可以获取网格的概要信息，可以用来确定代理服务器导致的问题；而 `proxy-config` 命令则可以用来观察 Envoy 的配置并对问题进行诊断。

要试用下面的命令，首先要满足下列两个条件中的一个：

* 一个部署了 Istio 和 Bookinfo 的 Kubernetes 集群（例如使用[安装步骤](/zh/docs/setup/kubernetes/install/kubernetes/#安装步骤)中所写的 `istio.yaml` 完成 Istio 的安装，并完成 [Bookinfo 应用部署](/zh/docs/examples/bookinfo/#如果在-kubernetes-中运行)）。

或者

* Kubernetes 环境下的 Istio 网格上运行自己的应用。

## 获取网格的概要情况

`proxy-status` 命令能够用来获取网格的概要情况。如果怀疑某个 Sidecar 无法获取配置，或者同步失败，就可以用这个命令来进行验证。

{{< text bash >}}
$ istioctl proxy-status
PROXY                                                  CDS        LDS        EDS               RDS          PILOT
details-v1-6dcc6fbb9d-wsjz4.default                    SYNCED     SYNCED     SYNCED (100%)     SYNCED       istio-pilot-75bdf98789-tfdvh
istio-egressgateway-c49694485-l9d5l.istio-system       SYNCED     SYNCED     SYNCED (100%)     NOT SENT     istio-pilot-75bdf98789-tfdvh
istio-ingress-6458b8c98f-7ks48.istio-system            SYNCED     SYNCED     SYNCED (100%)     NOT SENT     istio-pilot-75bdf98789-n2kqh
istio-ingressgateway-7d6874b48f-qxhn5.istio-system     SYNCED     SYNCED     SYNCED (100%)     SYNCED       istio-pilot-75bdf98789-n2kqh
productpage-v1-6c886ff494-hm7zk.default                SYNCED     SYNCED     SYNCED (100%)     STALE        istio-pilot-75bdf98789-n2kqh
ratings-v1-5d9ff497bb-gslng.default                    SYNCED     SYNCED     SYNCED (100%)     SYNCED       istio-pilot-75bdf98789-n2kqh
reviews-v1-55d4c455db-zjj2m.default                    SYNCED     SYNCED     SYNCED (100%)     SYNCED       istio-pilot-75bdf98789-n2kqh
reviews-v2-686bbb668-99j76.default                     SYNCED     SYNCED     SYNCED (100%)     SYNCED       istio-pilot-75bdf98789-tfdvh
reviews-v3-7b9b5fdfd6-4r52s.default                    SYNCED     SYNCED     SYNCED (100%)     SYNCED       istio-pilot-75bdf98789-n2kqh
{{< /text >}}

如果一个代理没有出现在这个列表上，就说明该代理目前没有连接到 Pilot 实例上，不会接到任何配置。

* `SYNCED`：Envoy 已经接收到了 Pilot 发送的最新配置。
* `SYNCED (100%)`：Envoy 成功的同步了集群内的所有端点。
* `NOT SENT`：Pilot 尚未向 Envoy 发送任何数据，这通常是因为 Pilot 没有需要发送的内容。
* `STALE`：Pilot 已经向 Envoy 发出了更新，但是还没有收到响应。这很可能意味着 Envoy 和 Pilot 之间的网络存在故障，或者是 Istio 自身的 Bug。

## 获取 Envoy 和 Istio Pilot 之间的配置差异

`proxy-status` 命令还可以通过一个 Proxy ID 作为输入，来获取 Envoy 已经载入的配置和 Pilot 将要发送的配置之间的差异，这有助于识别同步失败的问题，并且对原因分析也有帮助。

{{< text bash json >}}
$ istioctl proxy-status details-v1-6dcc6fbb9d-wsjz4.default
--- Pilot Clusters
+++ Envoy Clusters
@@ -374,36 +374,14 @@
             "edsClusterConfig": {
                "edsConfig": {
                   "ads": {

                   }
                },
                "serviceName": "outbound|443||public-cr0bdc785ce3f14722918080a97e1f26be-alb1.kube-system.svc.cluster.local"
-            },
-            "connectTimeout": "1.000s",
-            "circuitBreakers": {
-               "thresholds": [
-                  {
-
-                  }
-               ]
-            }
-         }
-      },
-      {
-         "cluster": {
-            "name": "outbound|53||kube-dns.kube-system.svc.cluster.local",
-            "type": "EDS",
-            "edsClusterConfig": {
-               "edsConfig": {
-                  "ads": {
-
-                  }
-               },
-               "serviceName": "outbound|53||kube-dns.kube-system.svc.cluster.local"
             },
             "connectTimeout": "1.000s",
             "circuitBreakers": {
                "thresholds": [
                   {

                   }

Listeners Match
Routes Match
{{< /text >}}

这些内容中不难发现，监听器和路由都是匹配的，但是集群定义未能同步。

## 深入了解 Envoy 配置

`proxy-config` 命令能够用来查看某个 Envoy 实例的配置。通过对 Istio 配置和自定义资源的查看不能确诊问题时，这个命令会大有帮助。要获取网格中一个 Pod 的集群、监听器和路由的概要信息，只要使用如下命令（可以根据需要把 `clusters` 替换为 `listeners` 或者 `routes`）：

{{< text bash >}}
$ istioctl proxy-config clusters -n istio-system istio-ingressgateway-7d6874b48f-qxhn5
SERVICE FQDN                                                                     PORT      SUBSET     DIRECTION     TYPE
BlackHoleCluster                                                                 -         -          -             STATIC
details.default.svc.cluster.local                                                9080      -          outbound      EDS
heapster.kube-system.svc.cluster.local                                           80        -          outbound      EDS
istio-citadel.istio-system.svc.cluster.local                                     8060      -          outbound      EDS
istio-citadel.istio-system.svc.cluster.local                                     10514      -         outbound      EDS
istio-egressgateway.istio-system.svc.cluster.local                               80        -          outbound      EDS
...
{{< /text >}}

要对 Envoy 进行除错，首先要了解一下 Envoy 的集群、监听器、路由、端点的概念，以及这些对象之间的交互过程。我们会使用 `proxy-config` 命令的 `-o json` 参数，并对结果进行过滤，来追踪 Envoy 对请求（从 `productpage` Pod 发向 `reviews` Pod 上的 `reviews:9080`）的决策过程：

1. 如果查询一个 Pod 的监听器概要信息，会看到 Istio 生成了如下的监听器：

    * `0.0.0.0:15001` 的监听器会接收所有出入 Pod 的流量，然后将请求转交给一个虚拟监听器。
    * 服务 IP 的虚拟监听器，用于 TCP/HTTPS 的非 HTTP 出站流量。
    * Pod IP 的虚拟监听器，用于暴露入站流量的端口。
    * `0.0.0.0` 的虚拟监听器用于出站的 HTTP 流量。

    {{< text bash >}}
    $ istioctl proxy-config listeners productpage-v1-6c886ff494-7vxhs
    ADDRESS            PORT      TYPE
    172.21.252.250     15005     TCP <--+
    172.21.252.250     15011     TCP    |
    172.21.79.56       42422     TCP    |
    172.21.160.5       443       TCP    |
    172.21.157.6       443       TCP    |
    172.21.117.222     443       TCP    |
    172.21.0.10        53        TCP    |
    172.21.126.131     443       TCP    |   Receives outbound non-HTTP traffic for relevant IP:PORT pair from listener `0.0.0.0_15001`
    172.21.160.5       31400     TCP    |
    172.21.81.159      9102      TCP    |
    172.21.0.1         443       TCP    |
    172.21.126.131     80        TCP    |
    172.21.119.8       443       TCP    |
    172.21.112.64      80        TCP    |
    172.21.179.54      443       TCP    |
    172.21.165.197     443       TCP <--+
    0.0.0.0            9090      HTTP <-+
    0.0.0.0            8060      HTTP   |
    0.0.0.0            15010     HTTP   |
    0.0.0.0            15003     HTTP   |
    0.0.0.0            15004     HTTP   |
    0.0.0.0            10514     HTTP   |   Receives outbound HTTP traffic for relevant port from listener `0.0.0.0_15001`
    0.0.0.0            15007     HTTP   |
    0.0.0.0            8080      HTTP   |
    0.0.0.0            9091      HTTP   |
    0.0.0.0            9080      HTTP   |
    0.0.0.0            80        HTTP <-+
    0.0.0.0            15001     TCP    // Receives all inbound and outbound traffic to the pod from IP tables and hands over to virtual listener
    172.30.164.190     9080      HTTP   // Receives all inbound traffic on 9080 from listener `0.0.0.0_15001`
    {{< /text >}}

1. 由上边的概要信息可以看出，每个 Sidecar 都有一个绑定到 `0.0.0.0:15001` 的监听器，IP tables 会路由 Pod 中所有的入站和出站流量到这一地址。这个监听器的 `useOriginalDst` 设置为 True，表明他会根据原始目的地来选择监听器，并将流量转发给最合适的监听器。如果找不到匹配的虚拟监听器，就会把请求发送给 `BlackHoleCluster`，它会返回一个 404。

    {{< text bash json >}}
    $ istioctl proxy-config listeners productpage-v1-6c886ff494-7vxhs --port 15001 -o json
    {
        "name": "virtual",
        "address": {
            "socketAddress": {
                "address": "0.0.0.0",
                "portValue": 15001
            }
        },
        "filterChains": [
            {
                "filters": [
                    {
                        "name": "envoy.tcp_proxy",
                        "config": {
                            "cluster": "BlackHoleCluster",
                            "stat_prefix": "BlackHoleCluster"
                        }
                    }
                ]
            }
        ],
        "useOriginalDst": true
    }
    {{< /text >}}

1. 我们的请求是一个出站的 HTTP 请求，目标是 `9080`，因此这个请求应该提交给 `0.0.0.0:9080` 虚拟监听器。这个监听器会在它的 RDS 中查找路由配置，这个例子中，就是在 Pilot（通过 ADS）配置的 RDS 信息中查找 `9080`。

    {{< text bash json >}}
    $ istioctl proxy-config listeners productpage-v1-6c886ff494-7vxhs -o json --address 0.0.0.0 --port 9080
    ...
    "rds": {
        "config_source": {
            "ads": {}
        },
        "route_config_name": "9080"
    }
    ...
    {{< /text >}}

1. `9080` 路由配置在每个服务中只有一个虚拟主机。我们的请求是发向 `reviews` 服务的，所有 Envoy 会选择符合请求域名的虚拟主机。选定虚拟主机之后，Envoy 会选择匹配该请求的第一条路由。这里没有定义任何的高级路由，所以只有一个匹配所有请求的路由。这个路由告诉 Envoy 发送请求到 `outbound|9080||reviews.default.svc.cluster.local` 集群。

    {{< text bash json >}}
    $ istioctl proxy-config routes productpage-v1-6c886ff494-7vxhs --name 9080 -o json
    [
        {
            "name": "9080",
            "virtualHosts": [
                {
                    "name": "reviews.default.svc.cluster.local:9080",
                    "domains": [
                        "reviews.default.svc.cluster.local",
                        "reviews.default.svc.cluster.local:9080",
                        "reviews",
                        "reviews:9080",
                        "reviews.default.svc.cluster",
                        "reviews.default.svc.cluster:9080",
                        "reviews.default.svc",
                        "reviews.default.svc:9080",
                        "reviews.default",
                        "reviews.default:9080",
                        "172.21.152.34",
                        "172.21.152.34:9080"
                    ],
                    "routes": [
                        {
                            "match": {
                                "prefix": "/"
                            },
                            "route": {
                                "cluster": "outbound|9080||reviews.default.svc.cluster.local",
                                "timeout": "0.000s"
                            },
    ...
    {{< /text >}}

1. 这个集群被配置从 Pilot（通过 ADS）获取端点列表。所以 Envoy 会使用 `serviceName` 字段作为关键字在端点列表中进行查找，然后将请求转发给查出来的端点中的一个。

    {{< text bash json >}}
    $ istioctl proxy-config clusters productpage-v1-6c886ff494-7vxhs --fqdn reviews.default.svc.cluster.local -o json
    [
        {
            "name": "outbound|9080||reviews.default.svc.cluster.local",
            "type": "EDS",
            "edsClusterConfig": {
                "edsConfig": {
                    "ads": {}
                },
                "serviceName": "outbound|9080||reviews.default.svc.cluster.local"
            },
            "connectTimeout": "1.000s",
            "circuitBreakers": {
                "thresholds": [
                    {}
                ]
            }
        }
    ]
    {{< /text >}}

1. 可以使用 `proxy-config endpoints` 命令来查看当前集群的可用端点。

    {{< text bash json >}}
    $ istioctl proxy-config endpoints productpage-v1-6c886ff494-7vxhs --cluster outbound|9080||reviews.default.svc.cluster.local
    ENDPOINT             STATUS      CLUSTER
    172.17.0.17:9080     HEALTHY     outbound|9080||reviews.default.svc.cluster.local
    172.17.0.18:9080     HEALTHY     outbound|9080||reviews.default.svc.cluster.local
    172.17.0.5:9080      HEALTHY     outbound|9080||reviews.default.svc.cluster.local
    {{< /text >}}

## 观察启动配置

我们已经了解了不少关于（绝大多数）来自于 Pilot 的配置方面的内容，Envoy 自身还有一些启动配置，例如在哪里查找 Pilot。用下面的命令可以查看这些信息：

{{< text bash json >}}
$ istioctl proxy-config bootstrap -n istio-system istio-ingressgateway-7d6874b48f-qxhn5
{
    "bootstrap": {
        "node": {
            "id": "router~172.30.86.14~istio-ingressgateway-7d6874b48f-qxhn5.istio-system~istio-system.svc.cluster.local",
            "cluster": "istio-ingressgateway",
            "metadata": {
                    "POD_NAME": "istio-ingressgateway-7d6874b48f-qxhn5",
                    "istio": "sidecar"
                },
            "buildVersion": "0/1.8.0-dev//RELEASE"
        },
...
{{< /text >}}

---
title: 调试 Envoy 和 Pilot
description: 描述如何调试 Pilot 和 Envoy。
weight: 5
keywords: [调试,proxy,状态,配置,pilot,envoy]
---

此任务演示如何使用 [`proxy-status`](/docs/reference/commands/istioctl/#istioctl-proxy-status) 和 [`proxy-config`](/docs/reference/commands/istioctl/#istioctl-proxy-config) 命令。`proxy-status` 命令允许您获取网格的概述并识别导致问题的代理。然后，`proxy-config` 可用于检查 Envoy 配置并用于问题排查。

## 开始之前

* 部署 Istio 和 Bookinfo 的 Kubernetes 集群（例如，如[安装步骤](/zh/docs/setup/kubernetes/install/kubernetes/#安装步骤)和 [Bookinfo 安装步骤](/zh/docs/examples/bookinfo/#如果在-kubernetes-中运行)中所述使用 `istio.yaml` 安装)。

或者

* 对于您在 Kubernetes 集群中运行的应用运行类似的命令。

## 网格概览

`proxy-status` 命令允许您获取网格的概述。如果你怀疑其中一个 sidecar 没有收到配置或不同步，那么代理状态会通知你。

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

如果此列表中缺少代理，则表示它当前未连接到 Pilot 实例，因此不会接收任何配置。

* `SYNCED` 表示 Envoy 已经确认了 Pilot 上次发送给它的配置。
* `SYNCED (100%)` 表示 Envoy 已经成功同步了集群中的所有端点。
* `NOT SENT` 表示 Pilot 没有发送任何信息给 Envoy。这通常是因为 Pilot 没有任何数据可以发送。
* `STALE` 表示 Pilot 已向 Envoy 发送更新但尚未收到确认。这通常表明 Envoy 和 Pilot 之间的网络存在问题或 Istio 本身的错误。

## 检索 Envoy 和 Istio Pilot 之间的差异

`proxy-status` 命令还可用于通过提供代理 ID 来检索 Envoy 已加载的配置与 Pilot 要发送的配置之间的差异。这可以帮助您准确定位不同步的内容及其问题所在。

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

在这里，您可以看到监听器和路由匹配但集群并不同步。

## Envoy 配置深度解析

`proxy-config` 命令可用于查看给定的 Envoy 实例的配置方式。然后，可以通过查看 Istio 配置和自定义资源来查明无法检测到的任何问题。要获取给定 pod 的集群、监听器或路由的基本摘要，请使用以下命令（在需要时更改监听器或路由的集群）：

{{< text bash >}}
$ istioctl proxy-config clusters -n istio-system istio-ingressgateway-7d6874b48f-qxhn5
SERVICE FQDN                                                                     PORT      SUBSET     DIRECTION     TYPE
BlackHoleCluster                                                                 -         -          -             STATIC
details.default.svc.cluster.local                                                9080      -          outbound      EDS
heapster.kube-system.svc.cluster.local                                           80        -          outbound      EDS
istio-citadel.istio-system.svc.cluster.local                                     8060      -          outbound      EDS
istio-citadel.istio-system.svc.cluster.local                                     10514     -          outbound      EDS
istio-egressgateway.istio-system.svc.cluster.local                               80        -          outbound      EDS
...
{{< /text >}}

为了调试 Envoy，您需要了解 Envoy 集群/监听器/路由/端点以及它们之间如何进行交互。我们将使用带有 `-o json` 和过滤标志的 `proxy-config` 命令来追踪 Envoy 以确定将请求从 `productpage` pod 发送到了 `reviews:9080` 的 reviews pod 上。

1. 如果您在 pod 上查询监听器摘要，您会注意到 Istio 会生成以下监听器：
    *  `0.0.0.0:15001` 上的监听器接收进出 pod 的所有流量，然后将请求移交给虚拟监听器。
    * 每个 service IP 一个虚拟监听器，每个出站 TCP/HTTPS 流量一个非 HTTP 监听器。
    * 每个 pod 入站流量暴露的端口一个虚拟监听器。
    * 每个 出站 HTTP 流量的 HTTP  `0.0.0.0` 端口一个虚拟监听器。

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

1. 从上面的摘要中可以看出，每个 sidecar 都有一个绑定到 `0.0.0.0:15001` 的监听器，IP tables 将 pod 的所有入站和出站流量路由到这里。此监听器把 `useOriginalDst` 设置为 true，这意味着它将请求交给最符合请求原始目标的监听器。如果找不到任何匹配的虚拟监听器，它会将请求发送给返回 404 的 `BlackHoleCluster`。

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

1. 我们的请求是到 `9080` 端口的 HTTP 出站请求，这意味着它被切换到 `0.0.0.0:9080` 虚拟监听器。然后，此监听器在其配置的 RDS 中查找路由配置。在这种情况下，它将查找由 Pilot 配置的 RDS 中的路由 `9080`（通过 ADS）。

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

1. `9080` 路由配置仅为每个服务提供虚拟主机。我们的请求正在前往 reviews 服务，因此 Envoy 将选择我们的请求与域匹配的虚拟主机。一旦在域上匹配，Envoy 会查找与请求匹配的第一条路径。在这种情况下，我们没有任何高级路由，因此只有一条路由匹配所有内容。这条路由告诉 Envoy 将请求发送到`outbound|9080||reviews.default.svc.cluster.local` 集群。

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

1. 此集群配置为从 Pilot（通过 ADS）检索关联的端点。因此，Envoy 将使用 `serviceName` 字段作为密钥来查找端点列表并将请求代理到其中一个端点。

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

1. 可以使用 `proxy-config` 命令查看当前集群中可用的 endpoints。

    {{< text bash json >}}
    $ istioctl proxy-config endpoints productpage-v1-6c886ff494-7vxhs --cluster outbound|9080||reviews.default.svc.cluster.local
    ENDPOINT             STATUS      CLUSTER
    172.17.0.17:9080     HEALTHY     outbound|9080||reviews.default.svc.cluster.local
    172.17.0.18:9080     HEALTHY     outbound|9080||reviews.default.svc.cluster.local
    172.17.0.5:9080      HEALTHY     outbound|9080||reviews.default.svc.cluster.local
    {{< /text >}}

## 检查 Bootstrap 配置

到目前为止，我们已经查看了（主要）从 Pilot 检索到的配置，但是 Envoy 需要一些引导程序配置，其中包含可以找到 Pilot 的信息。要查看此内容，请使用以下命令：

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

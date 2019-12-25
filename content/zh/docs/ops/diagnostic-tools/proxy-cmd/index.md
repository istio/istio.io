---
title: 调试 Envoy 和 Pilot
description: 描述诊断与流量管理相关的 Envoy 配置问题的工具和技术。
weight: 20
keywords: [debug,proxy,status,config,pilot,envoy]
aliases:
    - /zh/help/ops/traffic-management/proxy-cmd
    - /zh/help/ops/misc
    - /zh/help/ops/troubleshooting/proxy-cmd
---

Istio 提供了两个非常有价值的命令来帮助诊断流量管理配置相关的问题，[`proxy-status`](/zh/docs/reference/commands/istioctl/#istioctl-proxy-status) 和 [`proxy-config`](/zh/docs/reference/commands/istioctl/#istioctl-proxy-config) 命令。`proxy-status` 命令容许您获取网格的概况，并识别出导致问题的代理。`proxy-config` 可以被用于检查 Envoy 配置和诊断问题。

如果您想尝试以下的命令，需要：

* 有一个安装了 Istio 和 Bookinfo 应用的 Kubernetes 集群（正如在
[安装步骤](/zh/docs/setup/getting-started/) 和
[Bookinfo 安装步骤](/zh/docs/examples/bookinfo/#deploying-the-application)所描述的那样）。

或者

* 使用类似的命令在 Kubernetes 集群中运行您自己的应用。

## 获取网格概况{#get-an-overview-of-your-mesh}

`proxy-status` 命令容许您获取网格的概况。如果您怀疑某一个 sidecar 没有接收到配置或配置不同步时，`proxy-status` 将告诉您原因。

{{< text bash >}}
$ istioctl proxy-status
PROXY                                                  CDS        LDS        EDS               RDS          PILOT                            VERSION
details-v1-6dcc6fbb9d-wsjz4.default                    SYNCED     SYNCED     SYNCED     SYNCED       istio-pilot-75bdf98789-tfdvh     1.1.2
istio-egressgateway-c49694485-l9d5l.istio-system       SYNCED     SYNCED     SYNCED     NOT SENT     istio-pilot-75bdf98789-tfdvh     1.1.2
istio-ingress-6458b8c98f-7ks48.istio-system            SYNCED     SYNCED     SYNCED     NOT SENT     istio-pilot-75bdf98789-n2kqh     1.1.2
istio-ingressgateway-7d6874b48f-qxhn5.istio-system     SYNCED     SYNCED     SYNCED     SYNCED       istio-pilot-75bdf98789-n2kqh     1.1.2
productpage-v1-6c886ff494-hm7zk.default                SYNCED     SYNCED     SYNCED     STALE        istio-pilot-75bdf98789-n2kqh     1.1.2
ratings-v1-5d9ff497bb-gslng.default                    SYNCED     SYNCED     SYNCED     SYNCED       istio-pilot-75bdf98789-n2kqh     1.1.2
reviews-v1-55d4c455db-zjj2m.default                    SYNCED     SYNCED     SYNCED     SYNCED       istio-pilot-75bdf98789-n2kqh     1.1.2
reviews-v2-686bbb668-99j76.default                     SYNCED     SYNCED     SYNCED     SYNCED       istio-pilot-75bdf98789-tfdvh     1.1.2
reviews-v3-7b9b5fdfd6-4r52s.default                    SYNCED     SYNCED     SYNCED     SYNCED       istio-pilot-75bdf98789-n2kqh     1.1.2
{{< /text >}}

如果列表中缺少代理，这意味着它目前没有连接到 Pilot 实例，因此不会接收任何配置。

* `SYNCED` 意思是 Envoy 知晓了 Pilot 已经将最新的配置发送给了它。
* `NOT SENT` 意思是 Pilot 没有发送任何信息给 Envoy。这通常是因为 Pilot 没什么可发送的。
* `STALE` 意思是 Pilot 已经发送了一个更新到 Envoy，但还没有收到应答。这通常意味着 Envoy 和 Pilot 之间存在网络问题，或者 Istio 自身的 bug。

## 检查 Envoy 和 Istio Pilot 的差异{#retrieve-diffs-between-envoy-and-Istio-pilot}

通过提供代理 ID，`proxy-status` 命令还可以用来检查 Envoy 已加载的配置和 Pilot 发送给它的配置有什么异同，这可以帮您准确定位哪些配置是不同步的，以及问题出在哪里。

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

从这儿可以看到，监听器和路由是匹配的，但集群不同步。

## 深入 Envoy 配置{#deep-dive-into-envoy-configuration}

`proxy-config` 命令可以用来查看给定的 Envoy 是如何配置的。这样就可以通过 Istio 配置和自定义资源来查明任何您无法检测到的问题。下面的命令为给定 Pod 提供了集群、监听器或路由的基本概要（当需要时可以为监听器或路由改变集群）：

{{< text bash >}}
$ istioctl proxy-config cluster -n istio-system istio-ingressgateway-7d6874b48f-qxhn5
SERVICE FQDN                                                                     PORT      SUBSET     DIRECTION     TYPE
BlackHoleCluster                                                                 -         -          -             STATIC
details.default.svc.cluster.local                                                9080      -          outbound      EDS
heapster.kube-system.svc.cluster.local                                           80        -          outbound      EDS
istio-citadel.istio-system.svc.cluster.local                                     8060      -          outbound      EDS
istio-citadel.istio-system.svc.cluster.local                                     15014     -          outbound      EDS
istio-egressgateway.istio-system.svc.cluster.local                               80        -          outbound      EDS
...
{{< /text >}}

为了调试 Envoy 您需要理解 Envoy 集群、监听器、路由、endpoints 以及它们是如何交互的。我们将使用带有 `-o json` 参数的 `proxy-config` 命令，根据标志过滤出并跟随特定的 Envoy，它将请求从 `productpage` pod 发送到 `reviews` pod 9080 端口。

1. 如果您在一个 Pod 上查询监听器概要信息，您将注意到 Istio 生成了下面的监听器：
    *  `0.0.0.0:15001` 监听器接收所有进出 Pod 的流量，然后转发请求给一个虚拟监听器。
    * 每个服务 IP 一个虚拟监听器，针对每一个非 HTTP 的外部 TCP/HTTPS 流量。
    * Pod IP 上的虚拟监听器，针对内部流量暴露的端口。
    * `0.0.0.0` 监听器，针对外部 HTTP 流量的每个 HTTP 端口。

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
    0.0.0.0            15014     HTTP   |   Receives outbound HTTP traffic for relevant port from listener `0.0.0.0_15001`
    0.0.0.0            15007     HTTP   |
    0.0.0.0            8080      HTTP   |
    0.0.0.0            9091      HTTP   |
    0.0.0.0            9080      HTTP   |
    0.0.0.0            80        HTTP <-+
    0.0.0.0            15001     TCP    // Receives all inbound and outbound traffic to the pod from IP tables and hands over to virtual listener
    172.30.164.190     9080      HTTP   // Receives all inbound traffic on 9080 from listener `0.0.0.0_15001`
    {{< /text >}}

1. 从上面的信息可以看到，每一个 sidecar 有一个绑定到 `0.0.0.0:15001` 的监听器，来确定 IP 表将所有进出 Pod 的流量路由到哪里。监听器设置 `useOriginalDst` 为 true 意味着它将请求传递给最适合原始请求目的地的监听器。如果找不到匹配的虚拟监听器，它会将请求发送到直接连接到目的地的 `PassthroughCluster`。

    {{< text bash json >}}
    $ istioctl proxy-config listeners productpage-v1-6c886ff494-7vxhs --port 15001 -o json
    [
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
                                "cluster": "PassthroughCluster",
                                "stat_prefix": "PassthroughCluster"
                            }
                        }
                    ]
                }
            ],
            "useOriginalDst": true
        }
    ]
    {{< /text >}}

1. 我们的请求是到端口 `9080` 的出站 HTTP 请求，它将被传递给 `0.0.0.0:9080` 的虚拟监听器。这一监听器将检索在它配置的 RDS 里的路由配置。在这个例子中它将寻找 Pilot（通过 ADS）配置在 RDS 中的路由 `9080`。

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

1. 对每个服务，`9080` 路由配置只有一个虚拟主机。我们的请求会走到 reviews 服务，因此 Envoy 将选择一个虚拟主机把请求匹配到一个域。一旦匹配到，Envoy 会寻找请求匹配到的第一个路由。本例中我们没有设置任何高级路由规则，因此路由会匹配任何请求。这一路由告诉 Envoy 发送请求到 `outbound|9080||reviews.default.svc.cluster.local` 集群。

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

1. 此集群配置为从 Pilot（通过 ADS）检索关联的 endpoints。所以 Envoy 会使用 `serviceName` 字段作为主键，来检查 endpoint 列表并把请求代理到其中之一。

    {{< text bash json >}}
    $ istioctl proxy-config cluster productpage-v1-6c886ff494-7vxhs --fqdn reviews.default.svc.cluster.local -o json
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

1. 要查看此集群当前可用的 endpoint，请使用 `proxy-config` endpoints 命令。

    {{< text bash json >}}
    $ istioctl proxy-config endpoints productpage-v1-6c886ff494-7vxhs --cluster "outbound|9080||reviews.default.svc.cluster.local"
    ENDPOINT             STATUS      OUTLIER CHECK     CLUSTER
    172.17.0.17:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    172.17.0.18:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    172.17.0.5:9080      HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    {{< /text >}}

## 检查 bootstrap 配置{#inspecting-bootstrap-configuration}

到目前为止，我们已经查看了从 Pilot 检索到的配置（大部分），然而 Envoy 需要一些 bootstrap 配置，其中包括诸如在何处可以找到 Pilot 之类的信息。使用下面的命令查看：

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

## 验证到 Istio Pilot 的连通性{#verifying-connectivity-to-Istio-pilot}

验证与 Pilot 的连通性是一个有用的故障排除步骤。服务网格内的每个代理容器都应该能和 Pilot 通信。这可以通过几个简单的步骤来实现：

1.  获取 Istio Ingress pod 的名称：

    {{< text bash >}}
    $ INGRESS_POD_NAME=$(kubectl get po -n istio-system | grep ingressgateway\- | awk '{print$1}'); echo ${INGRESS_POD_NAME};
    {{< /text >}}

1.  通过 exec 进入 Istio Ingress pod：

    {{< text bash >}}
    $ kubectl exec -it $INGRESS_POD_NAME -n istio-system /bin/bash
    {{< /text >}}

1.  使用 `curl` 测试与 Pilot 的连通性。下面的示例使用了默认的 Pilot 配置参数和开启双向 TLS 来调用 v1 注册 API：

    {{< text bash >}}
    $ curl -k --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem --key /etc/certs/key.pem https://istio-pilot:8080/debug/edsz
    {{< /text >}}

    如果双向 TLS 是关闭的：

    {{< text bash >}}
    $ curl http://istio-pilot:8080/debug/edsz
    {{< /text >}}

对网格内的每个服务，您将会收到一个响应，列举了 "service-key" 和 "hosts"。

## Istio 使用的 Envoy 版本是什么？{#what-envoy-version-is-Istio-using}

要在部署中找出 Envoy 的版本，您可以通过 `exec` 进入容器并查询 `server_info` endpoint：

{{< text bash >}}
$ kubectl exec -it PODNAME -c istio-proxy -n NAMESPACE pilot-agent request GET server_info
{
 "version": "48bc83d8f0582fc060ef76d5aa3d75400e739d9e/1.12.0-dev/Clean/RELEASE/BoringSSL"
}
{{< /text >}}

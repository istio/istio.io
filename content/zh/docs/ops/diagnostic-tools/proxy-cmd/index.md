---
title: 调试 Envoy 和 Istiod
description: 描述诊断与流量管理相关的 Envoy 配置问题的工具和技术。
weight: 20
keywords: [debug,proxy,status,config,pilot,envoy]
aliases:
    - /zh/help/ops/traffic-management/proxy-cmd
    - /zh/help/ops/misc
    - /zh/help/ops/troubleshooting/proxy-cmd
owner: istio/wg-user-experience-maintainers
test: no
---

Istio 提供了两个非常有价值的命令来帮助诊断流量管理配置相关的问题，
[`proxy-status`](/zh/docs/reference/commands/istioctl/#istioctl-proxy-status)
和 [`proxy-config`](/zh/docs/reference/commands/istioctl/#istioctl-proxy-config)
命令。`proxy-status` 命令容许您获取网格的概况，并识别出导致问题的代理。
`proxy-config` 可以被用于检查 Envoy 配置和诊断问题。

如果您想尝试以下的命令，需要：

* 有一个安装了 Istio 和 Bookinfo 应用的 Kubernetes 集群（正如在
[安装步骤](/zh/docs/setup/getting-started/)和
[Bookinfo 安装步骤](/zh/docs/examples/bookinfo/#deploying-the-application)所描述的那样）。

或者

* 使用类似的命令在 Kubernetes 集群中运行您自己的应用。

## 获取网格概况{#get-an-overview-of-your-mesh}

`proxy-status` 命令容许您获取网格的概况。如果您怀疑某一个 Sidecar
没有接收到配置或配置不同步时，`proxy-status` 将告诉您原因。

{{< text bash >}}
$ istioctl proxy-status
NAME                                                   CDS        LDS        EDS        RDS          ISTIOD                      VERSION
details-v1-558b8b4b76-qzqsg.default                    SYNCED     SYNCED     SYNCED     SYNCED       istiod-6cf8d4f9cb-wm7x6     1.7.0
istio-ingressgateway-66c994c45c-cmb7x.istio-system     SYNCED     SYNCED     SYNCED     NOT SENT     istiod-6cf8d4f9cb-wm7x6     1.7.0
productpage-v1-6987489c74-nc7tj.default                SYNCED     SYNCED     SYNCED     SYNCED       istiod-6cf8d4f9cb-wm7x6     1.7.0
prometheus-7bdc59c94d-hcp59.istio-system               SYNCED     SYNCED     SYNCED     SYNCED       istiod-6cf8d4f9cb-wm7x6     1.7.0
ratings-v1-7dc98c7588-5m6xj.default                    SYNCED     SYNCED     SYNCED     SYNCED       istiod-6cf8d4f9cb-wm7x6     1.7.0
reviews-v1-7f99cc4496-rtsqn.default                    SYNCED     SYNCED     SYNCED     SYNCED       istiod-6cf8d4f9cb-wm7x6     1.7.0
reviews-v2-7d79d5bd5d-tj6kf.default                    SYNCED     SYNCED     SYNCED     SYNCED       istiod-6cf8d4f9cb-wm7x6     1.7.0
reviews-v3-7dbcdcbc56-t8wrx.default                    SYNCED     SYNCED     SYNCED     SYNCED       istiod-6cf8d4f9cb-wm7x6     1.7.0
{{< /text >}}

如果列表中缺少代理，这意味着它目前没有连接到 Istiod 实例，因此不会接收任何配置。

* `SYNCED` 意思是 Envoy 知晓了 {{< gloss >}}Istiod{{< /gloss >}}
  已经将最新的配置发送给了它。
* `NOT SENT` 意思是 Istiod 没有发送任何信息给 Envoy。这通常是因为
  Istiod 没什么可发送的。
* `STALE` 意思是 Istiod 已经发送了一个更新到 Envoy，但还没有收到应答。
  这通常意味着 Envoy 和 Istiod 之间存在网络问题，或者 Istio 自身的 bug。

## 检查 Envoy 和 Istiod 的差异 {#retrieve-diffs-between-envoy-and-Istiod}

通过提供代理 ID，`proxy-status` 命令还可以用来检查 Envoy
已加载的配置和 Istiod 发送给它的配置有什么异同，这可以帮您准确定位哪些配置是不同步的，
以及问题出在哪里。

{{< text bash json >}}
$ istioctl proxy-status details-v1-6dcc6fbb9d-wsjz4.default
--- Istiod Clusters
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
Routes Match (RDS last loaded at Tue, 04 Aug 2020 11:52:54 IST)
{{< /text >}}

从这儿可以看到，监听器和路由是匹配的，但集群不同步。

## 深入 Envoy 配置 {#deep-dive-into-envoy-configuration}

`proxy-config` 命令可以用来查看给定的 Envoy 是如何配置的。
这样就可以通过 Istio 配置和自定义资源来查明任何您无法检测到的问题。
下面的命令为给定 Pod 提供了集群、监听器或路由的基本概要（当需要时可以为监听器或路由改变集群）：

{{< text bash >}}
$ istioctl proxy-config cluster -n istio-system istio-ingressgateway-7d6874b48f-qxhn5
SERVICE FQDN                                                               PORT      SUBSET     DIRECTION     TYPE           DESTINATION RULE
BlackHoleCluster                                                           -         -          -             STATIC
agent                                                                      -         -          -             STATIC
details.default.svc.cluster.local                                          9080      -          outbound      EDS            details.default
istio-ingressgateway.istio-system.svc.cluster.local                        80        -          outbound      EDS
istio-ingressgateway.istio-system.svc.cluster.local                        443       -          outbound      EDS
istio-ingressgateway.istio-system.svc.cluster.local                        15021     -          outbound      EDS
istio-ingressgateway.istio-system.svc.cluster.local                        15443     -          outbound      EDS
istiod.istio-system.svc.cluster.local                                      443       -          outbound      EDS
istiod.istio-system.svc.cluster.local                                      853       -          outbound      EDS
istiod.istio-system.svc.cluster.local                                      15010     -          outbound      EDS
istiod.istio-system.svc.cluster.local                                      15012     -          outbound      EDS
istiod.istio-system.svc.cluster.local                                      15014     -          outbound      EDS
kube-dns.kube-system.svc.cluster.local                                     53        -          outbound      EDS
kube-dns.kube-system.svc.cluster.local                                     9153      -          outbound      EDS
kubernetes.default.svc.cluster.local                                       443       -          outbound      EDS
...
productpage.default.svc.cluster.local                                      9080      -          outbound      EDS
prometheus_stats                                                           -         -          -             STATIC
ratings.default.svc.cluster.local                                          9080      -          outbound      EDS
reviews.default.svc.cluster.local                                          9080      -          outbound      EDS
sds-grpc                                                                   -         -          -             STATIC
xds-grpc                                                                   -         -          -             STRICT_DNS
zipkin                                                                     -         -          -             STRICT_DNS
{{< /text >}}

为了调试 Envoy 您需要理解 Envoy 集群、监听器、路由、endpoints
以及它们是如何交互的。我们将使用带有 `-o json` 参数的 `proxy-config`
命令，根据标志过滤出并跟随特定的 Envoy，它将请求从 `productpage` Pod
发送到 `reviews` Pod 9080 端口。

1. 如果您在一个 Pod 上查询监听器概要信息，您将注意到 Istio 生成了下面的监听器：
    * `0.0.0.0:15001` 监听器接收所有进出 Pod 的流量，然后转发请求给一个虚拟监听器。
    * 每个服务 IP 一个虚拟监听器，针对每一个非 HTTP 的外部 TCP/HTTPS 流量。
    * Pod IP 上的虚拟监听器，针对内部流量暴露的端口。
    * `0.0.0.0` 监听器，针对外部 HTTP 流量的每个 HTTP 端口。

{{< text bash >}}
    $ istioctl proxy-config listeners productpage-v1-6c886ff494-7vxhs
    ADDRESS       PORT  MATCH                                            DESTINATION
    10.96.0.10    53    ALL                                              Cluster: outbound|53||kube-dns.kube-system.svc.cluster.local
    0.0.0.0       80    App: HTTP                                        Route: 80
    0.0.0.0       80    ALL                                              PassthroughCluster
    10.100.93.102 443   ALL                                              Cluster: outbound|443||istiod.istio-system.svc.cluster.local
    10.111.121.13 443   ALL                                              Cluster: outbound|443||istio-ingressgateway.istio-system.svc.cluster.local
    10.96.0.1     443   ALL                                              Cluster: outbound|443||kubernetes.default.svc.cluster.local
    10.100.93.102 853   App: HTTP                                        Route: istiod.istio-system.svc.cluster.local:853
    10.100.93.102 853   ALL                                              Cluster: outbound|853||istiod.istio-system.svc.cluster.local
    0.0.0.0       9080  App: HTTP                                        Route: 9080
    0.0.0.0       9080  ALL                                              PassthroughCluster
    0.0.0.0       9090  App: HTTP                                        Route: 9090
    0.0.0.0       9090  ALL                                              PassthroughCluster
    10.96.0.10    9153  App: HTTP                                        Route: kube-dns.kube-system.svc.cluster.local:9153
    10.96.0.10    9153  ALL                                              Cluster: outbound|9153||kube-dns.kube-system.svc.cluster.local
    0.0.0.0       15001 ALL                                              PassthroughCluster
    0.0.0.0       15006 Addr: 10.244.0.22/32:15021                       inbound|15021|mgmt-15021|mgmtCluster
    0.0.0.0       15006 Addr: 10.244.0.22/32:9080                        Inline Route: /*
    0.0.0.0       15006 Trans: tls; App: HTTP TLS; Addr: 0.0.0.0/0       Inline Route: /*
    0.0.0.0       15006 App: HTTP; Addr: 0.0.0.0/0                       Inline Route: /*
    0.0.0.0       15006 App: Istio HTTP Plain; Addr: 10.244.0.22/32:9080 Inline Route: /*
    0.0.0.0       15006 Addr: 0.0.0.0/0                                  InboundPassthroughClusterIpv4
    0.0.0.0       15006 Trans: tls; App: TCP TLS; Addr: 0.0.0.0/0        InboundPassthroughClusterIpv4
    0.0.0.0       15010 App: HTTP                                        Route: 15010
    0.0.0.0       15010 ALL                                              PassthroughCluster
    10.100.93.102 15012 ALL                                              Cluster: outbound|15012||istiod.istio-system.svc.cluster.local
    0.0.0.0       15014 App: HTTP                                        Route: 15014
    0.0.0.0       15014 ALL                                              PassthroughCluster
    0.0.0.0       15021 ALL                                              Inline Route: /healthz/ready*
    10.111.121.13 15021 App: HTTP                                        Route: istio-ingressgateway.istio-system.svc.cluster.local:15021
    10.111.121.13 15021 ALL                                              Cluster: outbound|15021||istio-ingressgateway.istio-system.svc.cluster.local
    0.0.0.0       15090 ALL                                              Inline Route: /stats/prometheus*
    10.111.121.13 15443 ALL                                              Cluster: outbound|15443||istio-ingressgateway.istio-system.svc.cluster.local
    {{< /text >}}

1. 从上面的信息可以看到，每一个 Sidecar 有一个绑定到 `0.0.0.0:15001`
   的监听器，来确定 IP 表将所有进出 Pod 的流量路由到哪里。监听器设置
   `useOriginalDst` 为 true 意味着它将请求传递给最适合原始请求目的地的监听器。
   如果找不到匹配的虚拟监听器，它会将请求发送到直接连接到目的地的 `PassthroughCluster`。

     {{< text bash json >}}
    $ istioctl proxy-config listeners productpage-v1-6c886ff494-7vxhs --port 15001 -o json
    [
        {
            "name": "virtualOutbound",
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
                            "name": "istio.stats",
                            "typedConfig": {
                                "@type": "type.googleapis.com/udpa.type.v1.TypedStruct",
                                "typeUrl": "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                                "value": {
                                    "config": {
                                        "configuration": "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n",
                                        "root_id": "stats_outbound",
                                        "vm_config": {
                                            "code": {
                                                "local": {
                                                    "inline_string": "envoy.wasm.stats"
                                                }
                                            },
                                            "runtime": "envoy.wasm.runtime.null",
                                            "vm_id": "tcp_stats_outbound"
                                        }
                                    }
                                }
                            }
                        },
                        {
                            "name": "envoy.tcp_proxy",
                            "typedConfig": {
                                "@type": "type.googleapis.com/envoy.config.filter.network.tcp_proxy.v2.TcpProxy",
                                "statPrefix": "PassthroughCluster",
                                "cluster": "PassthroughCluster"
                            }
                        }
                    ],
                    "name": "virtualOutbound-catchall-tcp"
                }
            ],
            "trafficDirection": "OUTBOUND",
            "hiddenEnvoyDeprecatedUseOriginalDst": true
        }
    ]
    {{< /text >}}

1. 我们的请求是到端口 `9080` 的出站 HTTP 请求，它将被传递给 `0.0.0.0:9080`
   的虚拟监听器。这一监听器将检索在它配置的 RDS 里的路由配置。
   在这个例子中它将寻找 Istiod（通过 ADS）配置在 RDS 中的路由 `9080`。

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

1. 对每个服务，`9080` 路由配置只有一个虚拟主机。我们的请求会走到 reviews
   服务，因此 Envoy 将选择一个虚拟主机把请求匹配到一个域。一旦匹配到，
   Envoy 会寻找请求匹配到的第一个路由。本例中我们没有设置任何高级路由规则，
   因此路由会匹配任何请求。这一路由告诉 Envoy 发送请求到
   `outbound|9080||reviews.default.svc.cluster.local` 集群。

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
                        "10.98.88.0",
                        "10.98.88.0:9080"
                    ],
                    "routes": [
                        {
                            "name": "default",
                            "match": {
                                "prefix": "/"
                            },
                            "route": {
                                "cluster": "outbound|9080||reviews.default.svc.cluster.local",
                                "timeout": "0s",
                            }
                        }
                    ]
    ...
    {{< /text >}}

1. 此集群配置为从 Istiod（通过 ADS）检索关联的 endpoints。
   所以 Envoy 会使用 `serviceName` 字段作为主键，来检查
   endpoint 列表并把请求代理到其中之一。

    {{< text bash json >}}
    $ istioctl proxy-config cluster productpage-v1-6c886ff494-7vxhs --fqdn reviews.default.svc.cluster.local -o json
    [
        {
            "name": "outbound|9080||reviews.default.svc.cluster.local",
            "type": "EDS",
            "edsClusterConfig": {
                "edsConfig": {
                    "ads": {},
                    "resourceApiVersion": "V3"
                },
                "serviceName": "outbound|9080||reviews.default.svc.cluster.local"
            },
            "connectTimeout": "10s",
            "circuitBreakers": {
                "thresholds": [
                    {
                        "maxConnections": 4294967295,
                        "maxPendingRequests": 4294967295,
                        "maxRequests": 4294967295,
                        "maxRetries": 4294967295
                    }
                ]
            },
        }
    ]
    {{< /text >}}

1. 要查看此集群当前可用的 endpoint，请使用 `proxy-config` endpoints 命令。

    {{< text bash json >}}
    $ istioctl proxy-config endpoints productpage-v1-6c886ff494-7vxhs --cluster "outbound|9080||reviews.default.svc.cluster.local"
    ENDPOINT            STATUS      OUTLIER CHECK     CLUSTER
    172.17.0.7:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    172.17.0.8:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    172.17.0.9:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    {{< /text >}}

## 检查 bootstrap 配置 {#inspecting-bootstrap-configuration}

到目前为止，我们已经查看了从 Istiod 检索到的配置（大部分），
然而 Envoy 需要一些 bootstrap 配置，其中包括诸如在何处可以找到
Istiod 之类的信息。使用下面的命令查看：

{{< text bash json >}}
$ istioctl proxy-config bootstrap -n istio-system istio-ingressgateway-7d6874b48f-qxhn5
{
    "bootstrap": {
        "node": {
            "id": "router~172.30.86.14~istio-ingressgateway-7d6874b48f-qxhn5.istio-system~istio-system.svc.cluster.local",
            "cluster": "istio-ingressgateway",
            "metadata": {
                    "CLUSTER_ID": "Kubernetes",
                    "EXCHANGE_KEYS": "NAME,NAMESPACE,INSTANCE_IPS,LABELS,OWNER,PLATFORM_METADATA,WORKLOAD_NAME,MESH_ID,SERVICE_ACCOUNT,CLUSTER_ID",
                    "INSTANCE_IPS": "10.244.0.7",
                    "ISTIO_PROXY_SHA": "istio-proxy:f98b7e538920abc408fbc91c22a3b32bc854d9dc",
                    "ISTIO_VERSION": "1.7.0",
                    "LABELS": {
                                "app": "istio-ingressgateway",
                                "chart": "gateways",
                                "heritage": "Tiller",
                                "istio": "ingressgateway",
                                "pod-template-hash": "68bf7d7f94",
                                "release": "istio",
                                "service.istio.io/canonical-name": "istio-ingressgateway",
                                "service.istio.io/canonical-revision": "latest"
                            },
                    "MESH_ID": "cluster.local",
                    "NAME": "istio-ingressgateway-68bf7d7f94-sp226",
                    "NAMESPACE": "istio-system",
                    "OWNER": "kubernetes://apis/apps/v1/namespaces/istio-system/deployments/istio-ingressgateway",
                    "ROUTER_MODE": "sni-dnat",
                    "SDS": "true",
                    "SERVICE_ACCOUNT": "istio-ingressgateway-service-account",
                    "WORKLOAD_NAME": "istio-ingressgateway"
                },
            "userAgentBuildVersion": {
                "version": {
                    "majorNumber": 1,
                    "minorNumber": 15
                },
                "metadata": {
                        "build.type": "RELEASE",
                        "revision.sha": "f98b7e538920abc408fbc91c22a3b32bc854d9dc",
                        "revision.status": "Clean",
                        "ssl.version": "BoringSSL"
                    }
            },
        },
...
{{< /text >}}

## 验证到 Istiod 的连通性 {#verifying-connectivity-to-Istiod}

验证与 Istiod 的连通性是一个有用的故障排除步骤。
服务网格内的每个代理容器都应该能和 Istiod 通信。
这可以通过几个简单的步骤来实现：

1. 创建一个 `sleep` pod：

    {{< text bash >}}
    $ kubectl create namespace foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n foo
    {{< /text >}}

1. 使用`curl`测试 Istiod 的连接。下面的示例使用默认 Istiod 配置参数和启用相互 TLS 调用 v1 注册 API：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- curl -sS istiod.istio-system:15014/version
    {{< /text >}}

您应该收到一个响应，其中列出了 Istiod 的版本。

## Istio 使用的 Envoy 版本是什么？{#what-envoy-version-is-Istio-using}

要在部署中找出 Envoy 的版本，您可以通过 `exec` 进入容器并查询 `server_info` 终端：

{{< text bash >}}
$ kubectl exec -it productpage-v1-6b746f74dc-9stvs -c istio-proxy -n default  -- pilot-agent request GET server_info --log_as_json | jq {version}
{
 "version": "2d4ec97f3ac7b3256d060e1bb8aa6c415f5cef63/1.17.0/Clean/RELEASE/BoringSSL"
}
{{< /text >}}

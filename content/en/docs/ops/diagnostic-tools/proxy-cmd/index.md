---
title: Debugging Envoy and Istiod
description: Describes tools and techniques to diagnose Envoy configuration issues related to traffic management.
weight: 20
keywords: [debug,proxy,status,config,pilot,envoy]
aliases:
    - /help/ops/traffic-management/proxy-cmd
    - /help/ops/misc
    - /help/ops/troubleshooting/proxy-cmd
owner: istio/wg-user-experience-maintainers
test: no
---

Istio provides two very valuable commands to help diagnose traffic management configuration problems,
the [`proxy-status`](/docs/reference/commands/istioctl/#istioctl-proxy-status)
and [`proxy-config`](/docs/reference/commands/istioctl/#istioctl-proxy-config) commands. The `proxy-status` command
allows you to get an overview of your mesh and identify the proxy causing the problem. Then `proxy-config` can be used
to inspect Envoy configuration and diagnose the issue.

If you want to try the commands described below, you can either:

* Have a Kubernetes cluster with Istio and Bookinfo installed (as described in
[installation steps](/docs/setup/getting-started/) and
[Bookinfo installation steps](/docs/examples/bookinfo/#deploying-the-application)).

OR

* Use similar commands against your own application running in a Kubernetes cluster.

## Get an overview of your mesh

The `proxy-status` command allows you to get an overview of your mesh. If you suspect one of your sidecars isn't
receiving configuration or is out of sync then `proxy-status` will tell you this.

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

If a proxy is missing from this list it means that it is not currently connected to a Istiod instance so will not be
receiving any configuration.

* `SYNCED` means that Envoy has acknowledged the last configuration {{< gloss >}}Istiod{{< /gloss >}} has sent to it.
* `NOT SENT` means that Istiod hasn't sent anything to Envoy. This usually is because Istiod has nothing to send.
* `STALE` means that Istiod has sent an update to Envoy but has not received an acknowledgement. This usually indicates
a networking issue between Envoy and Istiod or a bug with Istio itself.

## Retrieve diffs between Envoy and Istiod

The `proxy-status` command can also be used to retrieve a diff between the configuration Envoy has loaded and the
configuration Istiod would send, by providing a proxy ID. This can help you determine exactly what is out of sync and
where the issue may lie.

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

Here you can see that the listeners and routes match but the clusters are out of sync.

## Deep dive into Envoy configuration

The `proxy-config` command can be used to see how a given Envoy instance is configured. This can then be used to
pinpoint any issues you are unable to detect by just looking through your Istio configuration and custom resources.
To get a basic summary of clusters, listeners or routes for a given pod use the command as follows (changing clusters
for listeners or routes when required):

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

In order to debug Envoy you need to understand Envoy clusters/listeners/routes/endpoints and how they all interact.
We will use the `proxy-config` command with the `-o json` and filtering flags to follow Envoy as it determines where
to send a request from the `productpage` pod to the `reviews` pod at `reviews:9080`.

1. If you query the listener summary on a pod you will notice Istio generates the following listeners:
    * A listener on `0.0.0.0:15006` that receives all inbound traffic to the pod and a listener on `0.0.0.0:15001` that receives all outbound traffic to the pod, then hands the request over to a virtual listener.
    * A virtual listener per service IP, per each non-HTTP for outbound TCP/HTTPS traffic.
    * A virtual listener on the pod IP for each exposed port for inbound traffic.
    * A virtual listener on `0.0.0.0` per each HTTP port for outbound HTTP traffic.

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

1. From the above summary you can see that every sidecar has a listener bound to `0.0.0.0:15006` which is where IP tables routes all inbound pod traffic to and a listener bound to `0.0.0.0:15001` which is where IP tables routes all outbound pod traffic to. The `0.0.0.0:15001` listener hands the request over to the virtual listener that best matches the original destination of the request, if it can find a matching one. Otherwise, it sends the request to the `PassthroughCluster` which connects to the destination directly.

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

1. Our request is an outbound HTTP request to port `9080` this means it gets handed off to the `0.0.0.0:9080` virtual
listener. This listener then looks up the route configuration in its configured RDS. In this case it will be looking
up route `9080` in RDS configured by Istiod (via ADS).

    {{< text bash json >}}
    $ istioctl proxy-config listeners productpage-v1-6c886ff494-7vxhs -o json --address 0.0.0.0 --port 9080
    ...
    "rds": {
        "configSource": {
            "ads": {},
            "resourceApiVersion": "V3"
        },
        "routeConfigName": "9080"
    }
    ...
    {{< /text >}}

1. The `9080` route configuration only has a virtual host for each service. Our request is heading to the reviews
service so Envoy will select the virtual host to which our request matches a domain. Once matched on domain Envoy
looks for the first route that matches the request. In this case we don't have any advanced routing so there is only
one route that matches on everything. This route tells Envoy to send the request to the
`outbound|9080||reviews.default.svc.cluster.local` cluster.

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

1. This cluster is configured to retrieve the associated endpoints from Istiod (via ADS). So Envoy will then use the
`serviceName` field as a key to look up the list of Endpoints and proxy the request to one of them.

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

1. To see the endpoints currently available for this cluster use the `proxy-config` endpoints command.

    {{< text bash json >}}
    $ istioctl proxy-config endpoints productpage-v1-6c886ff494-7vxhs --cluster "outbound|9080||reviews.default.svc.cluster.local"
    ENDPOINT            STATUS      OUTLIER CHECK     CLUSTER
    172.17.0.7:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    172.17.0.8:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    172.17.0.9:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    {{< /text >}}

## Inspecting bootstrap configuration

So far we have looked at configuration retrieved (mostly) from Istiod, however Envoy requires some bootstrap configuration that
includes information like where Istiod can be found. To view this use the following command:

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

## Verifying connectivity to Istiod

Verifying connectivity to Istiod is a useful troubleshooting step. Every proxy container in the service mesh should be able to communicate with Istiod. This can be accomplished in a few simple steps:

1.  Create a `sleep` pod:

    {{< text bash >}}
    $ kubectl create namespace foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n foo
    {{< /text >}}

1.  Test connectivity to Istiod using `curl`. The following example invokes the v1 registration API using default Istiod configuration parameters and mutual TLS enabled:

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c sleep -n foo -- curl -sS istiod.istio-system:15014/version
    {{< /text >}}

You should receive a response listing the version of Istiod.

## What Envoy version is Istio using?

To find out the Envoy version used in deployment, you can `exec` into the container and query the `server_info` endpoint:

{{< text bash >}}
$ kubectl exec -it productpage-v1-6b746f74dc-9stvs -c istio-proxy -n default  -- pilot-agent request GET server_info --log_as_json | jq {version}
{
 "version": "2d4ec97f3ac7b3256d060e1bb8aa6c415f5cef63/1.17.0/Clean/RELEASE/BoringSSL"
}
{{< /text >}}

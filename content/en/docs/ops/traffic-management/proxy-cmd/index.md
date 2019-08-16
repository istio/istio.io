---
title: Debugging Envoy and Pilot
description: Describes tools and techniques to diagnose Envoy configuration issues related to traffic management.
weight: 40
keywords: [debug,proxy,status,config,pilot,envoy]
aliases:
    - /help/ops/traffic-management/proxy-cmd
---

Istio provides two very valuable commands to help diagnose traffic management configuration problems,
the [`proxy-status`](/docs/reference/commands/istioctl/#istioctl-proxy-status)
and [`proxy-config`](/docs/reference/commands/istioctl/#istioctl-proxy-config) commands. The `proxy-status` command
allows you to get an overview of your mesh and identify the proxy causing the problem. Then `proxy-config` can be used
to inspect Envoy configuration and diagnose the issue.

If you want to try the commands described below, you can either:

* Have a Kubernetes cluster with Istio and Bookinfo installed (e.g use `istio.yaml` as described in
[installation steps](/docs/setup/install/kubernetes/#installation-steps) and
[Bookinfo installation steps](/docs/examples/bookinfo/#if-you-are-running-on-kubernetes)).

OR

* Use similar commands against your own application running in a Kubernetes cluster.

## Get an overview of your mesh

The `proxy-status` command allows you to get an overview of your mesh. If you suspect one of your sidecars isn't
receiving configuration or is out of sync then `proxy-status` will tell you this.

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

If a proxy is missing from this list it means that it is not currently connected to a Pilot instance so will not be
receiving any configuration.

* `SYNCED` means that Envoy has acknowledged the last configuration Pilot has sent to it.
* `NOT SENT` means that Pilot hasn't sent anything to Envoy. This usually is because Pilot has nothing to send.
* `STALE` means that Pilot has sent an update to Envoy but has not received an acknowledgement. This usually indicates
a networking issue between Envoy and Pilot or a bug with Istio itself.

## Retrieve diffs between Envoy and Istio Pilot

The `proxy-status` command can also be used to retrieve a diff between the configuration Envoy has loaded and the
configuration Pilot would send, by providing a proxy ID. This can help you determine exactly what is out of sync and
where the issue may lie.

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

Here you can see that the listeners and routes match but the clusters are out of sync.

## Deep dive into Envoy configuration

The `proxy-config` command can be used to see how a given Envoy instance is configured. This can then be used to
pinpoint any issues you are unable to detect by just looking through your Istio configuration and custom resources.
To get a basic summary of clusters, listeners or routes for a given pod use the command as follows (changing clusters
for listeners or routes when required):

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

In order to debug Envoy you need to understand Envoy clusters/listeners/routes/endpoints and how they all interact.
We will use the `proxy-config` command with the `-o json` and filtering flags to follow Envoy as it determines where
to send a request from the `productpage` pod to the `reviews` pod at `reviews:9080`.

1. If you query the listener summary on a pod you will notice Istio generates the following listeners:
    * A listener on `0.0.0.0:15001` that receives all traffic into and out of the pod, then hands the request over to
    a virtual listener.
    * A virtual listener per service IP, per each non-HTTP for outbound TCP/HTTPS traffic.
    * A virtual listener on the pod IP for each exposed port for inbound traffic.
    * A virtual listener on `0.0.0.0` per each HTTP port for outbound HTTP traffic.

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

1. From the above summary you can see that every sidecar has a listener bound to `0.0.0.0:15001` which is where
IP tables routes all inbound and outbound pod traffic to. This listener has `useOriginalDst` set to true which means
it hands the request over to the listener that best matches the original destination of the request.
If it can't find any matching virtual listeners it sends the request to the `PassthroughCluster` which connects to the destination directly.

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

1. Our request is an outbound HTTP request to port `9080` this means it gets handed off to the `0.0.0.0:9080` virtual
listener. This listener then looks up the route configuration in its configured RDS. In this case it will be looking
up route `9080` in RDS configured by Pilot (via ADS).

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

1. This cluster is configured to retrieve the associated endpoints from Pilot (via ADS). So Envoy will then use the
`serviceName` field as a key to look up the list of Endpoints and proxy the request to one of them.

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

1. To see the endpoints currently available for this cluster use the `proxy-config` endpoints command.

    {{< text bash json >}}
    $ istioctl proxy-config endpoints productpage-v1-6c886ff494-7vxhs --cluster "outbound|9080||reviews.default.svc.cluster.local"
    ENDPOINT             STATUS      OUTLIER CHECK     CLUSTER
    172.17.0.17:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    172.17.0.18:9080     HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    172.17.0.5:9080      HEALTHY     OK                outbound|9080||reviews.default.svc.cluster.local
    {{< /text >}}

## Inspecting Bootstrap configuration

So far we have looked at configuration retrieved (mostly) from Pilot, however Envoy requires some bootstrap configuration that
includes information like where Pilot can be found. To view this use the following command:

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

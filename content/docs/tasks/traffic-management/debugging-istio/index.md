---
title: Debugging Istio
description: Shows how to debug Pilot and Envoy.
weight: 66
keywords: [debug,proxy,status,config]
---

This task demonstrates how to use the [proxy-status](/docs/reference/commands/istioctl/#istioctl-proxy-status) and [proxy-config](/docs/reference/commands/istioctl/#istioctl-proxy-config) commands.

## Before you begin

* Have a Kubernetes cluster with Istio and Bookinfo installed (e.g use istio.yaml as described in [installation steps](/docs/setup/kubernetes/quick-start/#installation-steps) and [bookinfo installation steps](https://preliminary.istio.io/docs/examples/bookinfo/#if-you-are-running-on-kubernetes)).

OR

* Follow along using similar commands against your own application running in a Kubernetes cluster.

## Get an overview of your mesh

The `proxy-status` command allows you to get an overview of your mesh. If you suspect one of your sidecars isn't receiving config or is out of sync then `proxy-status` will tell you this.

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

* `SYNCED` means that Envoy has acknowledged the last configuration Pilot has sent to it.
* `SYNCED (100%)` means that Envoy has successfully synced all of the endpoints in the cluster.
* `NOT SENT` means that Pilot hasn't sent anthing to Envoy. This usually is because Pilot has nothing to send.
* `STALE` means that Pilot has sent an update to Envoy but has not received an acknowledgement. This usually indicates a networking issue between Envoy and Pilot or a bug with Istio itself.

**If a proxy is missing from this list it means that it is not currently connected to a Pilot instance so will not be receiving any configuration.**

## Retrieve diffs between Envoy and Pilot

The `proxy-status` command can also be used to retrieve a diff between the configuration Envoy has loaded and the configuration Pilot would send, by providing a proxy ID. This can help you determine exactly what is out of sync and where the issue may lie.

{{< text bash >}}
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

Here we can see that the listeners and routes match but the clusters are out of sync. This specific diff is a bug with Pilot where it sends multiple kube-dns clusters to Envoy which automatically de-dups them, thus producing a diff in what is sent vs what Envoy loads in.

## Deep dive into Envoy configuration

The `proxy-config` command can be used to see how a given Envoy instance is configured. This can then be used to pinpoint any issues you are unable to detect by just looking through your Istio configuration and custom resources. To get a basic summary of clusters, listeners or routes for a given pod use the command as follows (changing clusters for listeners or routes when required):
{{< text bash >}}
$ istioctl proxy-config clusters -n istio-system istio-ingressgateway-7d6874b48f-qxhn5
SERVICE FQDN                                                                     PORT      SUBSET     DIRECTION     TYPE
BlackHoleCluster                                                                 -         -          -             STATIC
details.default.svc.cluster.local                                                9080      -          outbound      EDS
heapster.kube-system.svc.cluster.local                                           80        -          outbound      EDS
istio-citadel.istio-system.svc.cluster.local                                     8060      -          outbound      EDS
istio-citadel.istio-system.svc.cluster.local                                     9093      -          outbound      EDS
istio-egressgateway.istio-system.svc.cluster.local                               80        -          outbound      EDS
...
{{< /text >}}


In order to debug Envoy you need to understand Envoy clusters/listeners/routes/endpoints and how they all interact. We will use the `proxy-config` command with the `-o json` and filtering flags to follow Envoy as it determines where to send an incoming request for `/productpage` in the ingressgateway.

1. The `0.0.0.0_80` Envoy listener receives any request into the pod at port 80. It looks up the route configuration in its configured RDS. In this case it will be looking up route `http.80` in RDS configured by Pilot (via ADS).
{{< text bash >}}
$ istioctl proxy-config listeners -n istio-system istio-ingressgateway-7d6874b48f-qxhn5 -o json
"rds": {
    "config_source": {
        "ads": {}
    },
    "route_config_name": "http.80"
}
{{< /text >}}

2. The `http.80` route configuration only has a single virtual host with a wildcard domain. This means it will match all requests that get sent to this route configuration. Once matched on domain Envoy goes through each of the Virtual Hosts's routes for a match to decide which cluster it should send the request to. In this case we are making a request to `/productpage` so it will match this route and get sent to the `outbound|9080||productpage.default.svc.cluster.local` cluster.
{{< text bash >}}
$ istioctl proxy-config routes -n istio-system istio-ingressgateway-7d6874b48f-qxhn5 --name http.80 -o json
[
    {
        "name": "http.80",
        "virtualHosts": [
            {
                "name": "productpage:80",
                "domains": [
                    "*"
                ],
                "routes": [
                    {
                        "match": {
                            "path": "/productpage"
                        },
                        "route": {
                            "cluster": "outbound|9080||productpage.default.svc.cluster.local",
                            "timeout": "0.000s",
                            "useWebsocket": false
                        },
...
{{< /text >}}

3. This cluster is configured to retrieve the associated endpoints from Pilot (via ADS). So Envoy will then use the `serviceName` field as a key to look up the list of Endpoints and proxy the request to one of them.
{{< text bash >}}
$ istioctl proxy-config clusters -n istio-system istio-ingressgateway-7d6874b48f-qxhn5 --fqdn productpage.default.svc.cluster.local  -o json
[
    {
        "name": "outbound|9080||productpage.default.svc.cluster.local",
        "type": "EDS",
        "edsClusterConfig": {
            "edsConfig": {
                "ads": {}
            },
            "serviceName": "outbound|9080||productpage.default.svc.cluster.local"
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

## Inspecting Bootstrap config

So far we have looked at config retrieved (mostly) from Pilot, however Envoy requires some bootstrap config that includes information like where Pilot can be found. To view this use the following command:
{{< text bash >}}
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
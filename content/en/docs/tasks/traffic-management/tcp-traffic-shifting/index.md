---
title: TCP Traffic Shifting
description: Shows you how to migrate TCP traffic from an old to new version of a TCP service.
weight: 31
keywords: [traffic-management,tcp-traffic-shifting]
aliases:
    - /docs/tasks/traffic-management/tcp-version-migration.html
owner: istio/wg-networking-maintainers
test: yes
---

This task shows you how to shift TCP traffic from one version of a microservice to another.

A common use case is to migrate TCP traffic gradually from an older version of a microservice to a new one.
In Istio, you accomplish this goal by configuring a sequence of routing rules that redirect a percentage of TCP traffic
from one destination to another.

In this task, you will send 100% of the TCP traffic to `tcp-echo:v1`.
Then, you will route 20% of the TCP traffic to `tcp-echo:v2` using Istio's
weighted routing feature.

{{< boilerplate gateway-api-gamma-support >}}

## Before you begin

* Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

* Review the [Traffic Management](/docs/concepts/traffic-management) concepts doc.

## Set up the test environment

1.  To get started, create a namespace for testing TCP traffic shifting.

    {{< text bash >}}
    $ kubectl create namespace istio-io-tcp-traffic-shifting
    {{< /text >}}

1.  Deploy the [sleep]({{< github_tree >}}/samples/sleep) sample app to use as a test source for sending requests.

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n istio-io-tcp-traffic-shifting
    {{< /text >}}

1.  Deploy the `v1` and `v2` versions of the `tcp-echo` microservice.

    {{< text bash >}}
    $ kubectl apply -f @samples/tcp-echo/tcp-echo-services.yaml@ -n istio-io-tcp-traffic-shifting
    {{< /text >}}

## Apply weight-based TCP routing

1.  Route all TCP traffic to the `v1` version of the `tcp-echo` microservice.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f @samples/tcp-echo/tcp-echo-all-v1.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f @samples/tcp-echo/gateway-api/tcp-echo-all-v1.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Determine the ingress IP and port:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Follow the instructions in
[Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
to set the `TCP_INGRESS_PORT` and `INGRESS_HOST` environment variables.

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Use the following commands to set the `SECURE_INGRESS_PORT` and `INGRESS_HOST` environment variables:

{{< text bash >}}
$ kubectl wait --for=condition=programmed gtw tcp-echo-gateway -n istio-io-tcp-traffic-shifting
$ export INGRESS_HOST=$(kubectl get gtw tcp-echo-gateway -n istio-io-tcp-traffic-shifting -o jsonpath='{.status.addresses[0].value}')
$ export TCP_INGRESS_PORT=$(kubectl get gtw tcp-echo-gateway -n istio-io-tcp-traffic-shifting -o jsonpath='{.spec.listeners[?(@.name=="tcp-31400")].port}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  Confirm that the `tcp-echo` service is up and running by sending some TCP traffic.

    {{< text bash >}}
    $ export SLEEP=$(kubectl get pod -l app=sleep -n istio-io-tcp-traffic-shifting -o jsonpath={.items..metadata.name})
    $ for i in {1..20}; do \
    kubectl exec "$SLEEP" -c sleep -n istio-io-tcp-traffic-shifting -- sh -c "(date; sleep 1) | nc $INGRESS_HOST $TCP_INGRESS_PORT"; \
    done
    one Mon Nov 12 23:24:57 UTC 2022
    one Mon Nov 12 23:25:00 UTC 2022
    one Mon Nov 12 23:25:02 UTC 2022
    one Mon Nov 12 23:25:05 UTC 2022
    one Mon Nov 12 23:25:07 UTC 2022
    one Mon Nov 12 23:25:10 UTC 2022
    one Mon Nov 12 23:25:12 UTC 2022
    one Mon Nov 12 23:25:15 UTC 2022
    one Mon Nov 12 23:25:17 UTC 2022
    one Mon Nov 12 23:25:19 UTC 2022
    ...
    {{< /text >}}

    You should notice that all the timestamps have a prefix of _one_, which means that all traffic
    was routed to the `v1` version of the `tcp-echo` service.

4)  Transfer 20% of the traffic from `tcp-echo:v1` to `tcp-echo:v2` with the following command:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f @samples/tcp-echo/tcp-echo-20-v2.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f @samples/tcp-echo/gateway-api/tcp-echo-20-v2.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5) Wait a few seconds for the new rules to propagate and then confirm that the rule was replaced:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash yaml >}}
$ kubectl get virtualservice tcp-echo -o yaml -n istio-io-tcp-traffic-shifting
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
  ...
spec:
  ...
  tcp:
  - match:
    - port: 31400
    route:
    - destination:
        host: tcp-echo
        port:
          number: 9000
        subset: v1
      weight: 80
    - destination:
        host: tcp-echo
        port:
          number: 9000
        subset: v2
      weight: 20
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl get tcproute tcp-echo -o yaml -n istio-io-tcp-traffic-shifting
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TCPRoute
  ...
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: tcp-echo-gateway
    sectionName: tcp-31400
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: tcp-echo-v1
      port: 9000
      weight: 80
    - group: ""
      kind: Service
      name: tcp-echo-v2
      port: 9000
      weight: 20
...
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

6)  Send some more TCP traffic to the `tcp-echo` microservice.

    {{< text bash >}}
    $ export SLEEP=$(kubectl get pod -l app=sleep -n istio-io-tcp-traffic-shifting -o jsonpath={.items..metadata.name})
    $ for i in {1..20}; do \
    kubectl exec "$SLEEP" -c sleep -n istio-io-tcp-traffic-shifting -- sh -c "(date; sleep 1) | nc $INGRESS_HOST $TCP_INGRESS_PORT"; \
    done
    one Mon Nov 12 23:38:45 UTC 2022
    two Mon Nov 12 23:38:47 UTC 2022
    one Mon Nov 12 23:38:50 UTC 2022
    one Mon Nov 12 23:38:52 UTC 2022
    one Mon Nov 12 23:38:55 UTC 2022
    two Mon Nov 12 23:38:57 UTC 2022
    one Mon Nov 12 23:39:00 UTC 2022
    one Mon Nov 12 23:39:02 UTC 2022
    one Mon Nov 12 23:39:05 UTC 2022
    one Mon Nov 12 23:39:07 UTC 2022
    ...
    {{< /text >}}

    You should now notice that about 20% of the timestamps have a prefix of _two_, which means that
    80% of the TCP traffic was routed to the `v1` version of the `tcp-echo` service, while 20% was
    routed to `v2`.

## Understanding what happened

In this task you partially migrated TCP traffic from an old to new version of
the `tcp-echo` service using Istio's weighted routing feature. Note that this is
very different than doing version migration using the deployment features of
container orchestration platforms, which use instance scaling to manage the
traffic.

With Istio, you can allow the two versions of the `tcp-echo` service to scale up
and down independently, without affecting the traffic distribution between them.

For more information about version routing with autoscaling, check out the blog
article [Canary Deployments using Istio](/blog/2017/0.1-canary/).

## Cleanup

1. Remove the routing rules:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete -f @samples/tcp-echo/tcp-echo-all-v1.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -f @samples/tcp-echo/gateway-api/tcp-echo-all-v1.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2) Remove the `sleep` sample, `tcp-echo` application and test namespace:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@ -n istio-io-tcp-traffic-shifting
    $ kubectl delete -f @samples/tcp-echo/tcp-echo-services.yaml@ -n istio-io-tcp-traffic-shifting
    $ kubectl delete namespace istio-io-tcp-traffic-shifting
    {{< /text >}}

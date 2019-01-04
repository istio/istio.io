---
title: TCP Traffic Shifting
description: Shows you how to migrate TCP traffic from an old to new version of a TCP service.
weight: 26
keywords: [traffic-management,tcp-traffic-shifting]
aliases:
    - /docs/tasks/traffic-management/tcp-version-migration.html
---

This task shows you how to gradually migrate TCP traffic from one version of a
microservice to another. For example, you might migrate TCP traffic from an
older version to a new version.

A common use case is to migrate TCP traffic gradually from one version of a
microservice to another. In Istio, you accomplish this goal by configuring a
sequence of rules that route a percentage of TCP traffic to one service or
another. In this task, you will send 100% of the TCP traffic to `tcp-echo:v1`.
Then, you will route 20% of the TCP traffic to `tcp-echo:v2` using Istio's
weighted routing feature.

## Before you begin

* Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

* Review the [Traffic Management](/docs/concepts/traffic-management) concepts doc.

## Apply weight-based TCP routing

1.  To get started, deploy the `v1` version of the `tcp-echo` microservice.

    *   If you are using [manual sidecar injection](/docs/setup/kubernetes/sidecar-injection/#manual-sidecar-injection),
        use the following command

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/tcp-echo/tcp-echo-services.yaml@)
        {{< /text >}}

        The `istioctl kube-inject` command is used to manually modify the `tcp-echo-services.yaml`
        file before creating the deployments as documented [here](/docs/reference/commands/istioctl/#istioctl-kube-inject).

    *   If you are using a cluster with
        [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection)
        enabled, label the `default` namespace with `istio-injection=enabled`

        {{< text bash >}}
        $ kubectl label namespace default istio-injection=enabled
        {{< /text >}}

        Then simply deploy the services using `kubectl`

        {{< text bash >}}
        $ kubectl apply -f @samples/tcp-echo/tcp-echo-services.yaml@
        {{< /text >}}

1.  Next, route all TCP traffic to the `v1` version of the `tcp-echo` microservice.

    {{< text bash >}}
    $ kubectl apply -f @samples/tcp-echo/tcp-echo-all-v1.yaml@
    {{< /text >}}

1.  Confirm that the `tcp-echo` service is up and running.

    The `$INGRESS_HOST` variable below is the External IP address of the ingress, as explained in
the [Bookinfo](/docs/examples/bookinfo/#determining-the-ingress-ip-and-port) doc. To obtain the
`$INGRESS_PORT` value, use the following command.

    {{< text bash >}}
    $ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
    {{< /text >}}

    Send some TCP traffic to the `tcp-echo` microservice.

    {{< text bash >}}
    $ for i in {1..10}; do \
    docker run -e INGRESS_HOST=$INGRESS_HOST -e INGRESS_PORT=$INGRESS_PORT -it --rm busybox sh -c "(date; sleep 1) | nc $INGRESS_HOST $INGRESS_PORT"; \
    done
    one Mon Nov 12 23:24:57 UTC 2018
    one Mon Nov 12 23:25:00 UTC 2018
    one Mon Nov 12 23:25:02 UTC 2018
    one Mon Nov 12 23:25:05 UTC 2018
    one Mon Nov 12 23:25:07 UTC 2018
    one Mon Nov 12 23:25:10 UTC 2018
    one Mon Nov 12 23:25:12 UTC 2018
    one Mon Nov 12 23:25:15 UTC 2018
    one Mon Nov 12 23:25:17 UTC 2018
    one Mon Nov 12 23:25:19 UTC 2018
    {{< /text >}}

    You should notice that all the timestamps have a prefix of _one_, which means that all traffic
was routed to the `v1` version of the `tcp-echo` service.

1.  Transfer 20% of the traffic from `tcp-echo:v1` to `tcp-echo:v2` with the following command:

    {{< text bash >}}
    $ kubectl apply -f @samples/tcp-echo/tcp-echo-20-v2.yaml@
    {{< /text >}}

    Wait a few seconds for the new rules to propagate.

1. Confirm that the rule was replaced:

    {{< text bash yaml >}}
    $ kubectl get virtualservice tcp-echo -o yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: tcp-echo
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

1.  Send some more TCP traffic to the `tcp-echo` microservice.

    {{< text bash >}}
    $ for i in {1..10}; do \
    docker run -e INGRESS_HOST=$INGRESS_HOST -e INGRESS_PORT=$INGRESS_PORT -it --rm busybox sh -c "(date; sleep 1) | nc $INGRESS_HOST $INGRESS_PORT"; \
    done
    one Mon Nov 12 23:38:45 UTC 2018
    two Mon Nov 12 23:38:47 UTC 2018
    one Mon Nov 12 23:38:50 UTC 2018
    one Mon Nov 12 23:38:52 UTC 2018
    one Mon Nov 12 23:38:55 UTC 2018
    two Mon Nov 12 23:38:57 UTC 2018
    one Mon Nov 12 23:39:00 UTC 2018
    one Mon Nov 12 23:39:02 UTC 2018
    one Mon Nov 12 23:39:05 UTC 2018
    one Mon Nov 12 23:39:07 UTC 2018
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

1. Remove the `tcp-echo` application and routing rules:

    {{< text bash >}}
    $ kubectl delete -f @samples/tcp-echo/tcp-echo-all-v1.yaml@
    $ kubectl delete -f @samples/tcp-echo/tcp-echo-services.yaml@
    {{< /text >}}

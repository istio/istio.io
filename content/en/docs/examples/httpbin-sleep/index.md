---
title: Deploys httpbin and sleep
description: How to deploy httpbin and sleep.
weight: 10
---

This example shows how to deploy the `httpbin` and `sleep` applications that are used widely in many Istio tasks.

## Before you begin

If you haven't already done so, setup Istio by following the instructions
in the [installation guide](/docs/setup/).

## Deploying the application

To run the sample with Istio requires no changes to the
application itself. Instead, you simply need to configure and run the services in an
Istio-enabled environment, with Envoy sidecars injected along side each service.

To deploy `httpbin` and `sleep` in the existing `default` namespace:

1.  The default Istio installation uses [automatic sidecar injection](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection).
    Label the namespace that will host the application with `istio-injection=enabled`:

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    {{< /text >}}

1.  Deploy the applications using the `kubectl` command:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  Confirm all services and pods are correctly defined and running

    {{< text bash >}}
    $ kubectl get services
    NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
    httpbin      ClusterIP   10.4.17.178   <none>        8000/TCP   3h56m
    kubernetes   ClusterIP   10.4.16.1     <none>        443/TCP    35d
    sleep        ClusterIP   10.4.19.156   <none>        80/TCP     4h7m
    {{< /text >}}

    and

    {{< text bash >}}
    $ kubectl get pod
    NAME                       READY   STATUS    RESTARTS   AGE
    httpbin-546bf66965-zpfkk   2/2     Running   0          162m
    sleep-74564b477b-gmkvw     2/2     Running   1          162m
    {{< /text >}}

To deploy `httpbin` and `sleep` in a different namespace, say `staging`:

1.  Create a new `Kubernetes` namespace

    {{< text bash >}}
    $ kubectl create namespace staging
    {{< /text >}}

1.  Enable [automatic sidecar injection](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection) for this namespace.

    {{< text bash >}}
    $ kubectl label namespace staging istio-injection=enabled
    {{< /text >}}

1.  Deploy the applications using the `kubectl` command:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n staging
    {{< /text >}}

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n staging
    {{< /text >}}

    Notice there is a `-n staging` at the end to let the `Kubernetes API server` know where to deploy the applications.

1.  Confirm all services and pods are correctly defined and running

    {{< text bash >}}
    $ kubectl get services -n staging
    NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
    httpbin      ClusterIP   10.4.17.178   <none>        8000/TCP   2m
    sleep        ClusterIP   10.4.19.156   <none>        80/TCP     2m
    {{< /text >}}

    and

    {{< text bash >}}
    $ kubectl get pod -n staging
    NAME                       READY   STATUS    RESTARTS   AGE
    httpbin-546bf66965-zpfkk   2/2     Running   0          2m
    sleep-74564b477b-gmkvw     2/2     Running   1          2m
    {{< /text >}}

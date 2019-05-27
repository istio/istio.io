---
title: HA-Demo
description: Deploys a sample application in a high available fashion to show that Istio features are high available as well.
weight: 10
aliases:
    - /docs/samples/ha-demo.html
    - /docs/guides/ha-demo/index.html
---

This example deploys a small sample application composed of two components used
to demonstrate Istio features in a high available fashion. The service shows the latest news article.

The HA-demo application consists of two components:

* `news`. The `news` calls `article` to retrieve the actual news and returns it to the caller. The reason for introducing this service in front of `article` is to keep the client independent from the sidecar injection. So Istio can be updated without restarting the client.
* `article`. The `article` returns different headlines, depending on the version.

## Before you begin

If you haven't already done so, setup Istio by following the instructions
corresponding to your platform [installation guide for Kubernetes](/docs/setup/kubernetes).

## Deploy the ha-demo

### Deploying the application on Kubernetes

{{< text bash >}}
$ kubectl apply -f @samples/ha-demo/platform/kube/ha-demo.yaml@
{{< /text >}}

This creates two namespaces:

* One for the client
* One containing the ha-demo with sidecar injection enabled.

### Update Virtual Service

In order for the sidecar to re-route the traffic to different articles using Istio configuration object, we need to update the `Virtual Service` with the IP from the just generated Kubernetes service.

{{< text bash >}}
$ SERVICE_IP=$(kubectl get service -n ha-demo article -o=jsonpath='{.spec.clusterIP}') && echo $SERVICE_IP
$ kubectl get -n ha-demo virtualservice latest-article  -o json | jq --arg ip "$SERVICE_IP" '.spec.tcp[0].match[0].destinationSubnets[0]=$ip' | kubectl apply -f -
{{< /text >}}

### Install client

To test the service, we use `curl`. So any client using `curl` would do

{{< text bash >}}
$ kubectl apply -n client -f @samples/sleep/sleep.yaml@
{{< /text >}}

## Test ha-demo

### Enable Continuous Update

We continuously restart the deployments to show that the service can still be accessed without errors or hiccups.

{{< text bash >}}
$ ./@samples/ha-demo/restart-continuously.sh@ > /dev/null &
{{< /text >}}

You can monitor the pods being updated with

{{< text bash >}}
$ watch kubectl -n ha-demo get pods
{{< /text >}}

### Accessing the service from the client

By curling the service, we can verify that although the restarts are ongoing, no request fails

{{< text bash >}}
$ POD_NAME=$(kubectl -n client get pods -l app=sleep -o=jsonpath='{.items[0].metadata.name}') && echo $POD_NAME
$ while true; do kubectl exec -n client $POD_NAME -c sleep -- curl -s news.ha-demo.svc.cluster.local/article; done
{{< /text >}}

## Cleanup

When you're finished experimenting with the Bookinfo sample, uninstall and clean
it up using the following instructions corresponding to your Istio runtime environment.

1. Stop background process restarting the pods
  
    {{< text bash >}}
    $ ps | grep -v grep | grep "restart-continuously" | awk '{print $1}' | xargs kill
    {{< /text >}}

1.  Delete the created namespaces

    {{< text bash >}}
    $ kubectl delete namespaces client ha-demo
    {{< /text >}}

1.  Confirm clean cluster

    {{< text bash >}}
    $ kubectl get namespaces   #-- there should be nothing left created for this demo
    {{< /text >}}
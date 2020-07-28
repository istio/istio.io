---
title: Verify your deployment
description: Describes how to verify that your deployment works as intended on a flat network.
weight: 40
keywords:
owner: istio/wg-environments-maintainers
test: n/a
---

To verify that your {{< gloss >}}multicluster{{< /gloss >}} deployment works as
intended, deploy a `HelloWorld` example service to your
{{< gloss >}}service mesh{{< /gloss >}}. Depending on your deployment model,
you need to generate and send traffic within your mesh in a controlled way. This
section includes instructions to verify that traffic reaches the
{{< gloss "cluster" >}}clusters{{< /gloss >}} in your deployment following the
configured behavior.

## Before you begin

Ensure you have completed the following tasks:

- Verify you can access your clusters.

- [Complete the initial configuration](/docs/setup/install/multicluster/single-network/initial-configuration)
   of your multicluster deployment.

Additionally, complete at least one of the following tasks once:

- [Add a primary cluster](/docs/setup/install/multicluster/single-network/primary)
- [Add a remote cluster](/docs/setup/install/multicluster/single-network/remote)

## High-level flow

To verify your deployment, test the following scenarios as needed by your
model:

- Services in different clusters respond to the appropriate requests.
- Services reach other services in the same cluster.
- Services can reach other services in a different cluster.

At a high-level, the verification flow consists of the following steps:

1. Deploy a service to both clusters.

    {{< image width="50%"
    link="test-service.svg"
    caption="Deploy a service to both clusters"
    >}}

1. Deploy different versions of the service to each cluster.

    {{< image width="50%"
    link="test-versions.svg"
    caption="Deploy different versions of the service to each cluster"
    >}}

1. Deploy a load-generating service to both clusters.

    {{< image width="50%"
    link="test-loading.svg"
    caption="Deploy a load-generating service to both clusters"
    >}}

1. Send traffic from the load-generating service in one cluster to the test
   service.

    {{< image width="50%"
    link="from-c1.svg"
    caption="Send traffic from the load-generating service in `Cluster_1` to the test service"
    >}}

1. Send traffic from the load-generating service in the other cluster to the
   test service.

    {{< image width="50%"
    link="from-c2.svg"
    caption="Send traffic from the load-generating service in `Cluster_2` to the test service"
    >}}

The following sections provide detailed procedures to complete each of the steps.

## Deploy your test service

A client can call your `HelloWorld` {{< gloss "service endpoint">}}endpoints{{< /gloss >}}
if you configure DNS resolution for the `helloworld` hostname to an IP address.
After you deploy the `HelloWorld` service to your mesh, Istio configures DNS for
the `helloworld` hostname to resolve anywhere within the mesh. This guide uses
the HelloWorld service as an example, but you can use your own service. To
follow the best practice, create a namespace for your
service before deploying it.

Using the [previously set environment variables,](/docs/setup/install/multicluster/#env-var)
deploy the `HelloWorld` service to `Cluster_1` with the following steps:

1. Create the `sample` namespace in `Cluster_1` with the following command:

    {{< text bash >}}
    $ kubectl create --context=${CTX_1} namespace sample
    {{< /text >}}

1. Enable automatic sidecar injection for the `sample` namespace with the
   following command:

    {{< text bash >}}
    $ kubectl label --context=${CTX_1} namespace sample \
        istio-injection=enabled
    {{< /text >}}

1. Deploy the `HelloWorld` service to `Cluster_1` with the following command:

    {{< text bash >}}
    $ kubectl create --context=${CTX_1} \
        -f ${ISTIO}/samples/helloworld/helloworld.yaml \
        -l app=helloworld -n sample
    {{< /text >}}

Using the [previously set environment variables,](/docs/setup/install/multicluster/#env-var)
deploy the `HelloWorld` service to `Cluster_2` with the following steps:

1. Create the `sample` namespace in `Cluster_2` with the following command:

    {{< text bash >}}
    $ kubectl create --context=${CTX_2} namespace sample
    {{< /text >}}

1. Enable automatic sidecar injection for the `sample` namespace in
   `Cluster_2` with the following command:

    {{< text bash >}}
    $ kubectl label --context=${CTX_2} namespace sample \
        istio-injection=enabled
    {{< /text >}}

1. Deploy the `HelloWorld` service to `Cluster_2` with the following command:

    {{< text bash >}}
    $ kubectl create --context=${CTX_2} \
        -f ${ISTIO}/samples/helloworld/helloworld.yaml \
        -l app=helloworld -n sample
    {{< /text >}}

## Deploy different service versions to different clusters

To verify cross-cluster load balancing, deploy `v1` of the `HelloWorld` service to
`CLUSTER_1` and `v2` to `CLUSTER_2`.

Using the [previously set environment variables,](/docs/setup/install/multicluster/#env-var)
deploy the different versions of the service to the clusters with the following
steps:

1. Deploy `v1` of the `HelloWorld` service to `Cluster_1` with the following
   command:

    {{< text bash >}}
    $ kubectl create --context=${CTX_1} \
        -f ${ISTIO}/samples/helloworld/helloworld.yaml \
        -l app=helloworld -l version=v1 -n sample
    {{< /text >}}

1. Deploy `v2` of the HelloWorld service to `Cluster_2` with the following
   command:

    {{< text bash >}}
    $ kubectl create --context=${CTX_2} \
        -f ${ISTIO}/samples/helloworld/helloworld.yaml \
        -l app=helloworld -l version=v2 -n sample
    {{< /text >}}

1. Confirm the status `v1` of the HelloWorld service with the following
   command:

    {{< text bash >}}
    $ kubectl get pod --context=${CTX_1} -n sample
    NAME                            READY     STATUS    RESTARTS   AGE
    helloworld-v1-86f77cd7bd-cpxhv  2/2       Running   0          40s
    {{< /text >}}

1. Wait until the status of `helloworld-v1` is `Running`.
1. Confirm the status `v2` of the HelloWorld service with the following command:

    {{< text bash >}}
    $ kubectl get pod --context=${CTX_2} -n sample
    NAME                            READY     STATUS    RESTARTS   AGE
    helloworld-v2-758dd55874-6x4t8  2/2       Running   0          40s
    {{< /text >}}

1. After the status of `helloworld-v2` is `Running`, your cluster is ready
   to deploy a load-generating service.

## Deploy a load-generating service

To generate the traffic needed to verify your deployment, deploy the `sleep`
service to your clusters. We are using the `sleep` service as a simple
load-generating service. If you are using your own service to verify your
deployment, ensure that you have a traffic source creating a load for your
services.

Using the [previously set environment variables,](/docs/setup/install/multicluster/#env-var)
deploy the load-generating service to the clusters with the following steps:

1. Deploy the `sleep` service to `Cluster_1` with the following command:

    {{< text bash >}}
    $ kubectl apply --context=${CTX_1} \
        -f ${ISTIO}/samples/sleep/sleep.yaml -n sample
    {{< /text >}}

1. Deploy the `sleep` service to `Cluster_2` with the following command:

    {{< text bash >}}
    $ kubectl apply --context=${CTX_2} \
        -f ${ISTIO}/samples/sleep/sleep.yaml -n sample
    {{< /text >}}

1. Confirm the status of the `sleep` service on `Cluster_1` with the following
   command:

    {{< text bash >}}
    $ kubectl get pod --context=${CTX_1} -n sample -l app=sleep
    sleep-754684654f-n6bzf           2/2     Running   0          5s
    {{< /text >}}

1. Wait until the status of the `sleep` service is `Running`.
1. Confirm the status of the `sleep` service on `Cluster_2` with the following
   command:

    {{< text bash >}}
    $ kubectl get pod --context=${CTX_2} -n sample -l app=sleep
    sleep-754684654f-dzl9j           2/2     Running   0          5s
    {{< /text >}}

1. After the status of the `sleep` service is `Running`, you can verify that
   cross-cluster load balancing is working as expected.

## Verify cross-cluster load balancing

To verify that cross-cluster load balancing works as expected, call the
HelloWorld service several times using the sleep service. To ensure load
balancing is working properly, call the HelloWorld service from all clusters in
your deployment.

Using the [previously set environment variables,](/docs/setup/install/multicluster/#env-var)
verify cross-cluster load balancing with following steps:

1. Send one request on port 5000 from the `sleep` service on `Cluster_1` to the
   `HelloWorld` service with the following command:

    {{< text bash >}}
    $ kubectl exec --context=${CTX_1} -it -n sample -c sleep \
        $(kubectl get pod --context=${CTX_1} -n sample -l \
            app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl \
            helloworld.sample:5000/hello
    {{< /text >}}

1. To verify that the traffic reaches the endpoints of the `HelloWorld` service
   on your clusters, run the previous command multiple times.

1. If the endpoints on both clusters are responding, the output shows both
   `v1` and `v2` in the replies.

    {{< text console >}}
    Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
    Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
    ...
    {{< /text >}}

1. Send a request on port 5000 from the `sleep` service on `Cluster_2` to the `HelloWorld`
   service with the following command:

    {{< text bash >}}
    $ kubectl exec --context=${CTX_2} -it -n sample -c sleep \
        $(kubectl get pod --context=${CTX_2} -n sample -l \
            app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl \
            helloworld.sample:5000/hello
    {{< /text >}}

1. To verify that the traffic reaches the endpoints of the `HelloWorld` service
   on your clusters, run the previous command multiple times.

1. If the endpoints on both clusters are responding, the output shows both
   `v1` and `v2` in the replies.

    {{< text console >}}
    Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
    Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
    ...
    {{< /text >}}

**Congratulations!**

You successfully verified the deployment of your multicluster mesh.

## Clean up

After you no longer need your service mesh, you can remove Istio from your
clusters.

Remove Istio with the following steps:

1. If you verified your deployment, delete the namespaces used in
   verification with the following command:

    {{< text bash >}}
    $ kubectl delete namespace sample
    {{< /text >}}

1. Remove Istio from your clusters in the `istio-system` namespace with the
   following command:

    {{< text bash >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}

1. [Optional] Delete all files in your system's working directory with the
   following command:

    {{< text bash >}}
    $ rm -rf $WORK_DIR
    {{< /text >}}

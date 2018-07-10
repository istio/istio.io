---
title: Bookinfo Sample Application
description: Deploys a sample application composed of four separate microservices used to demonstrate various Istio features.
weight: 10
aliases:
    - /docs/samples/bookinfo.html
    - /docs/guides/bookinfo/index.html
---

> Note: This example assumes you will be using the new [v1alpha3 traffic management API](/blog/2018/v1alpha3-routing/).
The old API has been deprecated and will be removed in the next Istio release.
If you need to use the old version, you can follow the old instructions [here](https://archive.istio.io/v0.6/docs/guides/bookinfo.html),
but note that on Kubernetes you will need to run an additional command (`kubectl apply -f samples/bookinfo/kube/bookinfo-gateway.yaml`)
to define the Ingress, which previously was included in `bookinfo.yaml`.

This example deploys a sample application composed of four separate microservices used
to demonstrate various Istio features.

## Overview

In this example we will deploy a simple application that displays information about a
book, similar to a single catalog entry of an online book store. Displayed
on the page is a description of the book, book details (ISBN, number of
pages, and so on), and a few book reviews.

The Bookinfo application is broken into four separate microservices:

* *productpage*. The productpage microservice calls the *details* and *reviews* microservices to populate the page.
* *details*. The details microservice contains book information.
* *reviews*. The reviews microservice contains book reviews. It also calls the *ratings* microservice.
* *ratings*. The ratings microservice contains book ranking information that accompanies a book review.

There are 3 versions of the reviews microservice:

* Version v1 doesn't call the ratings service.
* Version v2 calls the ratings service, and displays each rating as 1 to 5 black stars.
* Version v3 calls the ratings service, and displays each rating as 1 to 5 red stars.

The end-to-end architecture of the application is shown below.

{{< image width="80%" ratio="68.52%"
    link="./noistio.svg"
    caption="Bookinfo Application without Istio"
    >}}

This application is polyglot, i.e., the microservices are written in different languages.
It’s worth noting that these services have no dependencies on Istio, but make an interesting
service mesh example, particularly because of the multitude of services, languages and versions
for the reviews service.

## Before you begin

If you haven't already done so, setup Istio by following the instructions
corresponding to your platform [installation guide](/docs/setup/).

## Deploying the application

To run the sample with Istio requires no changes to the
application itself. Instead, we simply need to configure and run the services in an
Istio-enabled environment, with Envoy sidecars injected along side each service.
The needed commands and configuration vary depending on the runtime environment
although in all cases the resulting deployment will look like this:

{{< image width="80%" ratio="59.08%"
    link="./withistio.svg"
    caption="Bookinfo Application"
    >}}

All of the microservices will be packaged with an Envoy sidecar that intercepts incoming
and outgoing calls for the services, providing the hooks needed to externally control,
via the Istio control plane, routing, telemetry collection, and policy enforcement
for the application as a whole.

To start the application, follow the instructions below corresponding to your Istio runtime environment.

### If you are running on Kubernetes

> If you use GKE, please ensure your cluster has at least 4 standard GKE nodes. If you use Minikube, please ensure you have at least 4GB RAM.

1. Change directory to the root of the Istio installation directory.

1.  Bring up the application containers:

    *   If you are using [manual sidecar injection](/docs/setup/kubernetes/sidecar-injection/#manual-sidecar-injection),
        use the following command

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/kube/bookinfo.yaml@)
        {{< /text >}}

        The `istioctl kube-inject` command is used to manually modify the `bookinfo.yaml`
        file before creating the deployments as documented [here](/docs/reference/commands/istioctl/#istioctl-kube-inject).

    *   If you are using a cluster with
        [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection)
        enabled, simply deploy the services using `kubectl`

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/kube/bookinfo.yaml@
        {{< /text >}}

    Either of the above commands launches all four microservices as illustrated in the above diagram.
    All 3 versions of the reviews service, v1, v2, and v3, are started.

    > In a realistic deployment, new versions of a microservice are deployed
    over time instead of deploying all versions simultaneously.

1.  Define the ingress gateway for the application:

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    {{< /text >}}

1.  Confirm all services and pods are correctly defined and running:

    {{< text bash >}}
    $ kubectl get services
    NAME                       CLUSTER-IP   EXTERNAL-IP   PORT(S)              AGE
    details                    10.0.0.31    <none>        9080/TCP             6m
    kubernetes                 10.0.0.1     <none>        443/TCP              7d
    productpage                10.0.0.120   <none>        9080/TCP             6m
    ratings                    10.0.0.15    <none>        9080/TCP             6m
    reviews                    10.0.0.170   <none>        9080/TCP             6m
    {{< /text >}}

    and

    {{< text bash >}}
    $ kubectl get pods
    NAME                                        READY     STATUS    RESTARTS   AGE
    details-v1-1520924117-48z17                 2/2       Running   0          6m
    productpage-v1-560495357-jk1lz              2/2       Running   0          6m
    ratings-v1-734492171-rnr5l                  2/2       Running   0          6m
    reviews-v1-874083890-f0qf0                  2/2       Running   0          6m
    reviews-v2-1343845940-b34q5                 2/2       Running   0          6m
    reviews-v3-1813607990-8ch52                 2/2       Running   0          6m
    {{< /text >}}

#### Determining the ingress IP and port

1.  Follow [these instructions](/docs/tasks/traffic-management/ingress/#determining-the-ingress-ip-and-ports) to set the `INGRESS_HOST` and `INGRESS_PORT` variables.

1.  Set `GATEWAY_URL`:

    {{< text bash >}}
    $ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    {{< /text >}}

1.  Proceed to [What's next](#what-s-next), below.

### If you are running on Docker with Consul

1.  Change directory to the root of the Istio installation directory.

1.  Bring up the application containers.

    To test with Consul, run the following commands:

    {{< text bash >}}
    $ docker-compose -f @samples/bookinfo/consul/bookinfo.yaml@ up -d
    $ docker-compose -f samples/bookinfo/consul/bookinfo.sidecars.yaml up -d
    {{< /text >}}

1.  Confirm that all docker containers are running:

    {{< text bash >}}
    $ docker ps -a
    {{< /text >}}

    > If the Istio Pilot container terminates, re-run the command from the previous step.

1.  Set GATEWAY_URL:

    {{< text bash >}}
    $ export GATEWAY_URL=localhost:9081
    {{< /text >}}

## What's next

To confirm that the Bookinfo application is running, run the following `curl` command:

{{< text bash >}}
$ curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
200
{{< /text >}}

You can also point your browser to `http://$GATEWAY_URL/productpage`
to view the Bookinfo web page. If you refresh the page several times, you should
see different versions of reviews shown in productpage, presented in a round robin style (red
stars, black stars, no stars), since we haven't yet used Istio to control the
version routing.

You can now use this sample to experiment with Istio's features for
traffic routing, fault injection, rate limiting, etc..
To proceed, refer to one or more of the [Istio Examples](/docs/examples),
depending on your interest. [Intelligent Routing](/docs/examples/intelligent-routing/)
is a good place to start for beginners.

## Cleanup

When you're finished experimenting with the Bookinfo sample, you can
uninstall and clean it up using the following instructions.

### Uninstall from Kubernetes environment

1.  Delete the routing rules and terminate the application pods

    {{< text bash >}}
    $ @samples/bookinfo/kube/cleanup.sh@
    {{< /text >}}

1.  Confirm shutdown

    {{< text bash >}}
    $ istioctl get gateway           #-- there should be no more gateway
    $ istioctl get virtualservices   #-- there should be no more virtual services
    $ kubectl get pods               #-- the Bookinfo pods should be deleted
    {{< /text >}}

### Uninstall from Docker environment

1.  Delete the routing rules and application containers

    In a Consul setup, run the following command:

    {{< text bash >}}
    $ @samples/bookinfo/consul/cleanup.sh@
    {{< /text >}}

1.  Confirm cleanup

    {{< text bash >}}
    $ istioctl get virtualservices   #-- there should be no more routing rules
    $ docker ps -a                   #-- the Bookinfo containers should be deleted
    {{< /text >}}

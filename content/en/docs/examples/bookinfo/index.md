---
title: Bookinfo Application
description: Deploys a sample application composed of four separate microservices used to demonstrate various Istio features.
weight: 10
aliases:
    - /docs/samples/bookinfo.html
    - /docs/guides/bookinfo/index.html
    - /docs/guides/bookinfo.html
owner: istio/wg-docs-maintainers
test: yes
---

This example deploys a sample application composed of four separate microservices used
to demonstrate various Istio features.

{{< tip >}}
If you installed Istio using the [Getting Started](/docs/setup/getting-started/)
instructions, you already have Bookinfo installed and you can skip most of these steps
and go directly to [Define the service versions](/docs/examples/bookinfo/#define-the-service-versions).
{{< /tip >}}

The application displays information about a
book, similar to a single catalog entry of an online book store. Displayed
on the page is a description of the book, book details (ISBN, number of
pages, and so on), and a few book reviews.

The Bookinfo application is broken into four separate microservices:

* `productpage`. The `productpage` microservice calls the `details` and `reviews` microservices to populate the page.
* `details`. The `details` microservice contains book information.
* `reviews`. The `reviews` microservice contains book reviews. It also calls the `ratings` microservice.
* `ratings`. The `ratings` microservice contains book ranking information that accompanies a book review.

There are 3 versions of the `reviews` microservice:

* Version v1 doesn't call the `ratings` service.
* Version v2 calls the `ratings` service, and displays each rating as 1 to 5 black stars.
* Version v3 calls the `ratings` service, and displays each rating as 1 to 5 red stars.

The end-to-end architecture of the application is shown below.

{{< image width="80%" link="./noistio.svg" caption="Bookinfo Application without Istio" >}}

This application is polyglot, i.e., the microservices are written in different languages.
It’s worth noting that these services have no dependencies on Istio, but make an interesting
service mesh example, particularly because of the multitude of services, languages and versions
for the `reviews` service.

## Before you begin

If you haven't already done so, setup Istio by following the instructions
in the [installation guide](/docs/setup/).

{{< boilerplate gateway-api-support >}}

## Deploying the application

To run the sample with Istio requires no changes to the
application itself. Instead, you simply need to configure and run the services in an
Istio-enabled environment.
{{< tabset category-name="dataplane-mode" >}}

{{< tab name="Sidecar Mode" category-value="sidecar-mode" >}}

In Sidecar mode, Envoy sidecars are injected along side each workload, and the resulting deployment will look like this:

{{< image width="80%" link="./withistio.svg" caption="Bookinfo Application" >}}

All of the microservices will be packaged with an Envoy sidecar that intercepts incoming
and outgoing calls for the services, providing the hooks needed to externally control,
via the Istio control plane, routing, telemetry collection, and policy enforcement
for the application as a whole.

{{< /tab >}}

{{< tab name="Ambient Mode" category-value="ambient-mode" >}}

In Ambient mode, ztunnel proxies are deployed on each node.
We can also put Waypoint proxies in front of each service
The resulting deployment will look like this:

FIXMEFIXMEFIXME ADD IMAGE

All of the microservices incoming and outgoing traffic will be intercepted by the ztunnel proxies,
providing the hooks needed to externally control, L4 routing, telemetry collection, and policy enforcement

Further, the ztunnel proxy will forward the traffic to a Waypoint proxy,
which provide the hooks needed to externally control, L7 routing, telemetry collection, and policy enforcement.

{{< /tab >}}

{{< /tabset >}}

### Start the application services

{{< tip >}}
If you using a cloud provider, please ensure your cluster has at least 4 nodes, each with 4GB of memory and 4 CPUS.
If you use Minikube, please ensure you have at least 4GB RAM.
{{< /tip >}}

1.  Change directory to the root of the Istio installation.

1.  Label your default namespace to enable Istio.

    {{< tabset category-name="dataplane-mode" >}}

    {{< tab name="Sidecar Mode" category-value="sidecar-mode" >}}

    The default Istio installation uses [automatic sidecar injection](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection).
    Label the namespace that will host the application with `istio-injection=enabled`:

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Ambient Mode" category-value="ambient-mode" >}}

    Label the namespace that will host the application with `istio.io/dataplane-mode=ambient` to automatically redirect traffic from your applications to ztunnel proxies:

    {{< text bash >}}
    $ kubectl label namespace default istio.io/dataplane-mode=ambient
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1.  Deploy your application using the `kubectl` command:

    
    {{< tabset category-name="dataplane-mode" >}}

    {{< tab name="Sidecar Mode" category-value="sidecar-mode" >}}

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    {{< /text >}}

    The command launches all four services shown in the `bookinfo` application architecture diagram.
    All 3 versions of the reviews service, v1, v2, and v3, are started.
    {{< /tab >}}

    {{< tab name="Ambient Mode" category-value="ambient-mode" >}}

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-waypoints.yaml@
    {{< /text >}}

    The command launches all four services shown in the `bookinfo` application architecture diagram, as well as a Waypoint proxy for each service.
    All 3 versions of the reviews service, v1, v2, and v3, are started.
    {{< /tab >}}

    {{< /tabset >}}

    {{< tip >}}
    In a realistic deployment, new versions of a microservice are deployed
    over time instead of deploying all versions simultaneously.
    {{< /tip >}}

1.  Confirm all services and pods are correctly defined and running:

    {{< tabset category-name="dataplane-mode" >}}

    {{< tab name="Sidecar Mode" category-value="sidecar-mode" >}}
    {{< text bash >}}
    $ kubectl get services
    NAME          TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
    details       ClusterIP   10.0.0.31    <none>        9080/TCP   6m
    kubernetes    ClusterIP   10.0.0.1     <none>        443/TCP    7d
    productpage   ClusterIP   10.0.0.120   <none>        9080/TCP   6m
    ratings       ClusterIP   10.0.0.15    <none>        9080/TCP   6m
    reviews       ClusterIP   10.0.0.170   <none>        9080/TCP   6m
    {{< /text >}}

    and

    {{< text bash >}}
    $ kubectl get pods
    NAME                             READY     STATUS    RESTARTS   AGE
    details-v1-1520924117-48z17      2/2       Running   0          6m
    productpage-v1-560495357-jk1lz   2/2       Running   0          6m
    ratings-v1-734492171-rnr5l       2/2       Running   0          6m
    reviews-v1-874083890-f0qf0       2/2       Running   0          6m
    reviews-v2-1343845940-b34q5      2/2       Running   0          6m
    reviews-v3-1813607990-8ch52      2/2       Running   0          6m
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Ambient Mode" category-value="ambient-mode" >}}
    {{< text bash >}}
    $ kubectl get services
    NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)               AGE
    details                    ClusterIP   10.96.30.105    <none>        9080/TCP              61m
    details-svc-waypoint       ClusterIP   10.96.250.18    <none>        15021/TCP,15008/TCP   43m
    kubernetes                 ClusterIP   10.96.0.1       <none>        443/TCP               63m
    productpage                ClusterIP   10.96.66.208    <none>        9080/TCP              61m
    productpage-svc-waypoint   ClusterIP   10.96.249.175   <none>        15021/TCP,15008/TCP   43m
    ratings                    ClusterIP   10.96.141.216   <none>        9080/TCP              61m
    ratings-svc-waypoint       ClusterIP   10.96.233.85    <none>        15021/TCP,15008/TCP   43m
    reviews                    ClusterIP   10.96.113.136   <none>        9080/TCP              61m
    reviews-svc-waypoint       ClusterIP   10.96.50.232    <none>        15021/TCP,15008/TCP   43m
    {{< /text >}}

    and

    {{< text bash >}}
    $ kubectl get pods
    NAME                                        READY   STATUS    RESTARTS   AGE
    details-svc-waypoint-766c4b6b86-qlt7j       1/1     Running   0          44m
    details-v1-766844796b-bwbzt                 1/1     Running   0          61m
    productpage-svc-waypoint-84c9c55bb8-6pgbz   1/1     Running   0          44m
    productpage-v1-54bb874995-54b2b             1/1     Running   0          61m
    ratings-svc-waypoint-6f9559f994-x6w94       1/1     Running   0          44m
    ratings-v1-5dc79b6bcd-qhdld                 1/1     Running   0          61m
    reviews-svc-waypoint-788d467dcf-qhm7v       1/1     Running   0          44m
    reviews-v1-598b896c9d-lrf6v                 1/1     Running   0          61m
    reviews-v2-556d6457d-t2qtq                  1/1     Running   0          61m
    reviews-v3-564544b4d6-6dn2m                 1/1     Running   0          61m
    {{< /text >}}
    {{< /tab >}}

    {{< /tabset >}}

1.  To confirm that the Bookinfo application is running, send a request to it by a `curl` command from some pod, for
    example from `ratings`:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

### Determine the ingress IP and port

Now that the Bookinfo services are up and running, you need to make the application accessible from outside of your
Kubernetes cluster, e.g., from a browser. A gateway is used for this purpose.

1. Create a gateway for the Bookinfo application:

    {{< tabset category-name="config-api" >}}

    {{< tab name="Istio APIs" category-value="istio-apis" >}}

    Create an [Istio Gateway](/docs/concepts/traffic-management/#gateways) using the following command:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    gateway.networking.istio.io/bookinfo-gateway created
    virtualservice.networking.istio.io/bookinfo created
    {{< /text >}}

    Confirm the gateway has been created:

    {{< text bash >}}
    $ kubectl get gateway
    NAME               AGE
    bookinfo-gateway   32s
    {{< /text >}}

    Follow [these instructions](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) to set the `INGRESS_HOST` and `INGRESS_PORT` variables for accessing the gateway. Return here, when they are set.

    {{< /tab >}}

    {{< tab name="Gateway API" category-value="gateway-api" >}}

    {{< boilerplate external-loadbalancer-support >}}

    Create a [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/) using the following command:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@
    gateway.gateway.networking.k8s.io/bookinfo-gateway created
    httproute.gateway.networking.k8s.io/bookinfo created
    {{< /text >}}

    Because creating a Kubernetes `Gateway` resource will also
    [deploy an associated proxy service](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment),
    run the following command to wait for the gateway to be ready:

    {{< text bash >}}
    $ kubectl wait --for=condition=programmed gtw bookinfo-gateway
    {{< /text >}}

    Get the gateway address and port from the bookinfo gateway resource:

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.status.addresses[0].value}')
    $ export INGRESS_PORT=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1.  Set `GATEWAY_URL`:

    {{< text bash >}}
    $ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    {{< /text >}}

## Confirm the app is accessible from outside the cluster

To confirm that the Bookinfo application is accessible from outside the cluster, run the following `curl` command:

{{< text bash >}}
$ curl -s "http://${GATEWAY_URL}/productpage" | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

You can also point your browser to `http://$GATEWAY_URL/productpage`
to view the Bookinfo web page. If you refresh the page several times, you should
see different versions of reviews shown in `productpage`, presented in a round robin style (red
stars, black stars, no stars), since we haven't yet used Istio to control the
version routing.

## Define the service versions

Before you can use Istio to control the Bookinfo version routing, you need to define the available
versions.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Istio uses *subsets*, in [destination rules](/docs/concepts/traffic-management/#destination-rules),
to define versions of a service.
Run the following command to create default destination rules for the Bookinfo services:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
{{< /text >}}

{{< tip >}}
The `default` and `demo` [configuration profiles](/docs/setup/additional-setup/config-profiles/) have [auto mutual TLS](/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls) enabled by default.
To enforce mutual TLS, use the destination rules in `samples/bookinfo/networking/destination-rule-all-mtls.yaml`.
{{< /tip >}}

Wait a few seconds for the destination rules to propagate.

You can display the destination rules with the following command:

{{< text bash >}}
$ kubectl get destinationrules -o yaml
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Unlike the Istio API, which uses `DestinationRule` subsets to define the versions of a service,
the Kubernetes Gateway API uses backend service definitions for this purpose.

Run the following command to create backend service definitions for the three versions of the `reviews` service:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-versions.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## What's next

You can now use this sample to experiment with Istio's features for
traffic routing, fault injection, rate limiting, etc.
To proceed, refer to one or more of the [Istio Tasks](/docs/tasks),
depending on your interest. [Configuring Request Routing](/docs/tasks/traffic-management/request-routing/)
is a good place to start for beginners.

## Cleanup

When you're finished experimenting with the Bookinfo sample, uninstall and clean
it up using the following command:

{{< text bash >}}
$ @samples/bookinfo/platform/kube/cleanup.sh@
{{< /text >}}

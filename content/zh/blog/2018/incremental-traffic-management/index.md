---
title: Incremental Istio Part 1, Traffic Management
description: How to use Istio for traffic management without deploying sidecar proxies.
publishdate: 2018-11-21
subtitle:
attribution: Sandeep Parikh
twitter: crcsmnky
keywords: [traffic-management,gateway]
target_release: 1.0
---

Traffic management is one of the critical benefits provided by Istio. At the heart of Istio’s traffic management is the ability to decouple traffic flow and infrastructure scaling. This lets you control your traffic in ways that aren’t possible without a service mesh like Istio.

For example, let’s say you want to execute a [canary deployment](https://martinfowler.com/bliki/CanaryRelease.html). With Istio, you can specify that **v1** of a service receives 90% of incoming traffic, while **v2** of that service only receives 10%. With standard Kubernetes deployments, the only way to achieve this is to manually control the number of available Pods for each version, for example 9 Pods running v1 and 1 Pod running v2. This type of manual control is hard to implement, and over time may have trouble scaling. For more information, check out [Canary Deployments using Istio](/blog/2017/0.1-canary/).

The same issue exists when deploying updates to existing services. While you can update deployments with Kubernetes, it requires replacing v1 Pods with v2 Pods. Using Istio, you can deploy v2 of your service and use built-in traffic management mechanisms to shift traffic to your updated services at a network level, then remove the v1 Pods.

In addition to canary deployments and general traffic shifting, Istio also gives you the ability to implement dynamic request routing (based on HTTP headers), failure recovery, retries, circuit breakers, and fault injection. For more information, check out the [Traffic Management documentation](/docs/concepts/traffic-management/).

This post walks through a technique that highlights a particularly useful way that you can implement Istio incrementally -- in this case, only the traffic management features -- without having to individually update each of your Pods.

## Setup: why implement Istio traffic management features?

Of course, the first question is: Why would you want to do this?

If you’re part of one of the many organizations out there that have a large cluster with lots of teams deploying, the answer is pretty clear. Let’s say Team A is getting started with Istio and wants to start some canary deployments on Service A, but Team B hasn’t started using Istio, so they don’t have sidecars deployed.

With Istio, Team A can still implement their canaries by having Service B call Service A through Istio’s ingress gateway.

## Background: traffic routing in an Istio mesh

But how can you use Istio’s traffic management capabilities without updating each of your applications’ Pods to include the Istio sidecar? Before answering that question, let’s take a quick high-level look at how traffic enters an Istio mesh and how it’s routed.

Pods that are part of the Istio mesh contain a sidecar proxy that is responsible for mediating all inbound and outbound traffic to the Pod. Within an Istio mesh, Pilot is responsible for converting high-level routing rules into configurations and propagating them to the sidecar proxies. That means when services communicate with one another, their routing decisions are determined from the client side.

Let’s say you have two services that are part of the Istio mesh, Service A and Service B. When A wants to communicate with B, the sidecar proxy of Pod A is responsible for directing traffic to Service B. For example, if you wanted to split traffic 50/50 across Service B v1 and v2, the traffic would flow as follows:

{{< image width="60%" link="./fifty-fifty.png" caption="50/50 Traffic Split" >}}

If Services A and B are not part of the Istio mesh, there is no sidecar proxy that knows how to route traffic to different versions of Service B. In that case you need to use another approach to get traffic from Service A to Service B, following the 50/50 rules you’ve setup.

Fortunately, a standard Istio deployment already includes a [Gateway](/docs/concepts/traffic-management/#gateways) that specifically deals with ingress traffic outside of the Istio mesh. This Gateway is used to allow ingress traffic from outside the cluster via an external load balancer, or to allow ingress traffic from within the Kubernetes cluster but outside the service mesh. It can be configured to proxy incoming ingress traffic to the appropriate Pods, even if they don’t have a sidecar proxy. While this approach allows you to leverage Istio’s traffic management features, it does mean that traffic going through the ingress gateway will incur an extra hop.

{{< image width="60%" link="./fifty-fifty-ingress-gateway.png" caption="50/50 Traffic Split using Ingress Gateway" >}}

## In action: traffic routing with Istio

A simple way to see this type of approach in action is to first setup your Kubernetes environment using the [Platform Setup](/docs/setup/platform-setup/) instructions, and then install the **minimal** Istio profile using [Helm](/docs/setup/install/helm/), including only the traffic management components (ingress gateway, egress gateway, Pilot). The following example uses [Google Kubernetes Engine](https://cloud.google.com/gke).

First, setup and configure [GKE](/docs/setup/platform-setup/gke/):

{{< text bash >}}
$ gcloud container clusters create istio-inc --zone us-central1-f
$ gcloud container clusters get-credentials istio-inc
$ kubectl create clusterrolebinding cluster-admin-binding \
   --clusterrole=cluster-admin \
   --user=$(gcloud config get-value core/account)
{{< /text >}}

Next, [install Helm](https://helm.sh/docs/securing_installation/) and [generate a minimal Istio install](/docs/setup/install/helm/) -- only traffic management components:

{{< text bash >}}
$ helm template install/kubernetes/helm/istio \
  --name istio \
  --namespace istio-system \
  --set security.enabled=false \
  --set galley.enabled=false \
  --set sidecarInjectorWebhook.enabled=false \
  --set mixer.enabled=false \
  --set prometheus.enabled=false \
  --set pilot.sidecar=false > istio-minimal.yaml
{{< /text >}}

Then create the `istio-system` namespace and deploy Istio:

{{< text bash >}}
$ kubectl create namespace istio-system
$ kubectl apply -f istio-minimal.yaml
{{< /text >}}

Next, deploy the Bookinfo sample without the Istio sidecar containers:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
{{< /text >}}

Now, configure a new Gateway that allows access to the reviews service from outside the Istio mesh, a new `VirtualService` that splits traffic evenly between v1 and v2 of the reviews service, and a set of new `DestinationRule` resources that match destination subsets to service versions:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: reviews-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - "*"
  gateways:
  - reviews-gateway
  http:
  - match:
    - uri:
        prefix: /reviews
    route:
    - destination:
        host: reviews
        subset: v1
      weight: 50
    - destination:
        host: reviews
        subset: v2
      weight: 50
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v3
    labels:
      version: v3
EOF
{{< /text >}}

Finally, deploy a pod that you can use for testing with `curl` (and without the Istio sidecar container):

{{< text bash >}}
$ kubectl apply -f @samples/sleep/sleep.yaml@
{{< /text >}}

## Testing your deployment

Now, you can test different behaviors using the `curl` commands via the sleep Pod.

The first example is to issue requests to the reviews service using standard Kubernetes service DNS behavior (**note**: [`jq`](https://stedolan.github.io/jq/) is used in the examples below to filter the output from `curl`):

{{< text bash >}}
$ export SLEEP_POD=$(kubectl get pod -l app=sleep \
  -o jsonpath={.items..metadata.name})
$ for i in `seq 3`; do \
  kubectl exec -it $SLEEP_POD curl http://reviews:9080/reviews/0 | \
  jq '.reviews|.[]|.rating?'; \
  done
{{< /text >}}

{{< text json >}}
{
  "stars": 5,
  "color": "black"
}
{
  "stars": 4,
  "color": "black"
}
null
null
{
  "stars": 5,
  "color": "red"
}
{
  "stars": 4,
  "color": "red"
}
{{< /text >}}

Notice how we’re getting responses from all three versions of the reviews service (`null` is from reviews v1 which doesn’t have ratings) and not getting the even split across v1 and v2. This is expected behavior because the `curl` command is using Kubernetes service load balancing across all three versions of the reviews service. In order to access the reviews 50/50 split we need to access the service via the ingress Gateway:

{{< text bash >}}
$ for i in `seq 4`; do \
  kubectl exec -it $SLEEP_POD curl http://istio-ingressgateway.istio-system/reviews/0 | \
  jq '.reviews|.[]|.rating?'; \
  done
{{< /text >}}

{{< text json >}}
{
  "stars": 5,
  "color": "black"
}
{
  "stars": 4,
  "color": "black"
}
null
null
{
  "stars": 5,
  "color": "black"
}
{
  "stars": 4,
  "color": "black"
}
null
null
{{< /text >}}

Mission accomplished! This post showed how to deploy a minimal installation of Istio that only contains the traffic management components (Pilot, ingress Gateway), and then use those components to direct traffic to specific versions of the reviews service. And it wasn't necessary to deploy the Istio sidecar proxy to gain these capabilities, so there was little to no interruption of existing workloads or applications.

Using the built-in ingress gateway (along with some `VirtualService` and `DestinationRule` resources) this post showed how you can easily leverage Istio’s traffic management for cluster-external ingress traffic and cluster-internal service-to-service traffic. This technique is a great example of an incremental approach to adopting Istio, and can be especially useful in real-world cases where Pods are owned by different teams or deployed to different namespaces.

---
title: Mesh Federation
subtitle: Federate distinct service mesh in an ad-hoc manner, with limited service exposure and cross-cluster traffic control
description: Federate distinct service mesh in an ad-hoc manner, with limited service exposure and cross-cluster traffic control.
publishdate: 2019-07-23
attribution: Vadim Eisenberg (IBM)
keywords: [traffic-management,multicluster,security,gateway,tls]
---

Currently there are [three patterns](https://istio.io/docs/setup/kubernetes/install/multicluster/) in Istio to create a
[multicluster service mesh](/docs/concepts/multicluster-deployments/#multicluster-service-mesh).
A _multicluster service mesh_ is a single _logical_ service mesh, spread among multiple Kubernetes clusters.
In such a service mesh, there is uniform identical naming of namespaces and services, all the services are exposed to
all the clusters and common identity and common trust are established between multiple clusters. The patterns differ by
the following criteria:

* The clusters are on a single (_flat_) network or on different networks
* The Istio control planes are shared between the clusters or each cluster has its own dedicated control plane

However, there are use cases when you want to connect different independent clusters while limiting exposure of services
from one cluster to other clusters and with strict control of which clusters may consume specific services of the
exposing cluster.
Sometimes different clusters are operated by different organizations that do not have common naming rules and didn't
establish common trust. We call such ad-hoc loosely-coupled connection between independent service meshes
_mesh federation_.

In this blog post I show how using standard Istio traffic control patterns you expose specific services in one
cluster to workloads in another cluster, in a controlled manner, and perform load balancing between the local and
remote services.

## Prerequisites

Two Kubernetes clusters (referred to as `cluster1` and `cluster2`) with default Istio installations

{{< boilerplate kubectl-multicluster-contexts >}}

## Initial setup

*   In each of the clusters, deploy the [sleep]({{< github_tree >}}/samples/sleep) sample app to use as a test source for
  sending requests.

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

### Setup the first cluster

*  Install the [Bookinfo](/docs/examples/bookinfo/) sample application,
[confirm the app is accessible outside the cluster](/docs/examples/bookinfo/#confirm-the-app-is-accessible-from-outside-the-cluster),
and [apply default destination rules](/docs/examples/bookinfo/#apply-default-destination-rules).

*   Direct the traffic to the _v1_ version of all the microservices:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    virtualservice.networking.istio.io/productpage created
    virtualservice.networking.istio.io/reviews created
    virtualservice.networking.istio.io/ratings created
    virtualservice.networking.istio.io/details created
    {{< /text >}}

    Access the web page of the Bookinfo application and verify that the reviews appear without stars, which means that the
_v1_ version of _reviews_ is used.

*   Delete the deployments of `reviews v2`, `reviews v3` and `ratings v1`:

    {{< text bash >}}
    $ kubectl delete deployment reviews-v2 reviews-v3 ratings-v1 --context=$CTX_CLUSTER1
    deployment.extensions "reviews-v2" deleted
    deployment.extensions "reviews-v3" deleted
    deployment.extensions "ratings-v1" deleted
    {{< /text >}}

    Access the web page of the Bookinfo application and verify that it continues to work as before.

*   Check the pods:

    {{< text bash >}}
    $ kubectl get pods --context=$CTX_CLUSTER1
    details-v1-59489d6fb6-m5s5j       2/2     Running   0          4h31m
    productpage-v1-689ff955c6-7qsk6   2/2     Running   0          4h31m
    reviews-v1-657b76fc99-lx46g       2/2     Running   0          4h31m
    sleep-57f9d6fd6b-px97z            2/2     Running   0          4h31m
    {{< /text >}}

    You should have three pods of the Bookinfo application and a pod for the sleep testing app.

### Setup the second cluster

*   Create the `bookinfo` namespace and label it for sidecar injection. Note that while you deployed the Bookinfo
application in the first cluster in the `default` namespace, you use the `bookinfo`
namespace in the second cluster. This is to demonstrate that you can use different namespaces in the clusters you
federate, there is no requirement for uniform naming.

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 namespace bookinfo
    $ kubectl label --context=$CTX_CLUSTER2 namespace bookinfo istio-injection=enabled
    namespace/bookinfo created
    namespace/bookinfo labeled
    {{< /text >}}

*   Deploy `reviews v2`, `reviews v3` and `ratings v1`:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER2 -l app!=ratings,app!=reviews,app!=details,app!=productpage -n bookinfo -f samples/bookinfo/platform/kube/bookinfo.yaml
    $  kubectl apply --context=$CTX_CLUSTER2 -l app=reviews,version=v2 -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    $  kubectl apply --context=$CTX_CLUSTER2 -l app=reviews,version=v3 -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    $  kubectl apply --context=$CTX_CLUSTER2 -l app=ratings -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    serviceaccount/bookinfo-details created
    serviceaccount/bookinfo-ratings created
    serviceaccount/bookinfo-reviews created
    serviceaccount/bookinfo-productpage created
    deployment.apps/reviews-v2 created
    deployment.apps/reviews-v3 created
    service/ratings created
    deployment.apps/ratings-v1 created
    {{< /text >}}

*   Check the pods in the `bookinfo` namespace:

    {{< text bash >}}
    $ kubectl get pods -n bookinfo --context=$CTX_CLUSTER2
    ratings-v1-85f65447f4-vk88z   2/2     Running   0          43s
    reviews-v2-5cfcfb547f-2t6l4   2/2     Running   0          50s
    reviews-v3-75b4759787-58wpr   2/2     Running   0          48s
    {{< /text >}}

    You should have three pods of the Bookinfo application.

*   Create a service for reviews. Call it `myreviews`, to demonstrate that you can use a different names for services in
    the clusters, there is no requirement for uniform naming in mesh federation.

    {{< text bash >}}
    $ kubectl apply -n bookinfo --context=$CTX_CLUSTER2 -f - <<EOF
    apiVersion: v1
    kind: Service
    metadata:
      name: myreviews
      labels:
        app: reviews
    spec:
      ports:
      - port: 9080
        name: http
      selector:
        app: reviews
    EOF
    {{< /text >}}

*   Verify that `myreviews.bookinfo` works as expected:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items..metadata.name}' --context=$CTX_CLUSTER2) -c sleep --context=$CTX_CLUSTER2 -- curl myreviews.bookinfo:9080/reviews/0
    {"id": "0","reviews": [{  "reviewer": "Reviewer1",  "text": "An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!", "rating": {"stars": 5, "color": "red"}},{  "reviewer": "Reviewer2",  "text": "Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.", "rating": {"stars": 4, "color": "red"}}]}
    {{< /text >}}

## Cleanup

{{< text bash >}}
$ kubectl delete --context=$CTX_CLUSTER2 -l app!=ratings,app!=reviews,app!=details,app!=productpage -n bookinfo -f samples/bookinfo/platform/kube/bookinfo.yaml
$  kubectl delete --context=$CTX_CLUSTER2 -l app=reviews,version=v2 -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo.yaml@
$  kubectl delete --context=$CTX_CLUSTER2 -l app=reviews,version=v3 -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo.yaml@
$  kubectl delete --context=$CTX_CLUSTER2 -l app=ratings -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo.yaml@
serviceaccount "bookinfo-details" deleted
serviceaccount "bookinfo-ratings" deleted
serviceaccount "bookinfo-reviews" deleted
serviceaccount "bookinfo-productpage" deleted
deployment.apps "reviews-v2" deleted
deployment.apps "reviews-v3" deleted
service "ratings" deleted
deployment.apps "ratings-v1" deleted
{{< /text >}}

## Summary

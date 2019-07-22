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

1. Install the [Bookinfo](/docs/examples/bookinfo/) sample application,
[confirm the app is accessible outside the cluster](/docs/examples/bookinfo/#confirm-the-app-is-accessible-from-outside-the-cluster),
and [apply default destination rules](/docs/examples/bookinfo/#apply-default-destination-rules).

1.  Direct the traffic to the _v1_ version of all the microservices:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    virtualservice.networking.istio.io/productpage created
    virtualservice.networking.istio.io/reviews created
    virtualservice.networking.istio.io/ratings created
    virtualservice.networking.istio.io/details created
    {{< /text >}}

    Access the web page of the Bookinfo application and verify that the reviews appear without stars, which means that the
_v1_ version of _reviews_ is used.

1.  Delete the deployments of `reviews v2`, `reviews v3` and `ratings v1`:

    {{< text bash >}}
    $ kubectl delete deployment reviews-v2 reviews-v3 ratings-v1 --context=$CTX_CLUSTER1
    deployment.extensions "reviews-v2" deleted
    deployment.extensions "reviews-v3" deleted
    deployment.extensions "ratings-v1" deleted
    {{< /text >}}

    Access the web page of the Bookinfo application and verify that it continues to work as before.

1.  Check the pods:

    {{< text bash >}}
    $ kubectl get pods --context=$CTX_CLUSTER1
    details-v1-59489d6fb6-m5s5j       2/2     Running   0          4h31m
    productpage-v1-689ff955c6-7qsk6   2/2     Running   0          4h31m
    reviews-v1-657b76fc99-lx46g       2/2     Running   0          4h31m
    sleep-57f9d6fd6b-px97z            2/2     Running   0          4h31m
    {{< /text >}}

    You should have three pods of the Bookinfo application and a pod for the sleep testing app.

### Setup the second cluster

1.  Create the `bookinfo` namespace and label it for sidecar injection. Note that while you deployed the Bookinfo
application in the first cluster in the `default` namespace, you use the `bookinfo`
namespace in the second cluster. This is to demonstrate that you can use different namespaces in the clusters you
federate, there is no requirement for uniform naming.

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 namespace bookinfo
    $ kubectl label --context=$CTX_CLUSTER2 namespace bookinfo istio-injection=enabled
    namespace/bookinfo created
    namespace/bookinfo labeled
    {{< /text >}}

1.  Deploy `reviews v2`, `reviews v3` and `ratings v1`:

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

1.  Check the pods in the `bookinfo` namespace:

    {{< text bash >}}
    $ kubectl get pods -n bookinfo --context=$CTX_CLUSTER2
    ratings-v1-85f65447f4-vk88z   2/2     Running   0          43s
    reviews-v2-5cfcfb547f-2t6l4   2/2     Running   0          50s
    reviews-v3-75b4759787-58wpr   2/2     Running   0          48s
    {{< /text >}}

    You should have three pods of the Bookinfo application.

1.  Create a service for reviews. Call it `myreviews`, to demonstrate that you can use a different names for services in
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

1.  Create destination rules for reviews and ratings:

    {{< text bash >}}
    $ kubectl apply -n bookinfo --context=$CTX_CLUSTER2 -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: reviews
    spec:
      host: myreviews
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
      subsets:
      - name: v2
        labels:
          version: v2
      - name: v3
        labels:
          version: v3
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: ratings
    spec:
      host: ratings
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
      subsets:
      - name: v1
        labels:
          version: v1
    EOF
    {{< /text >}}

1.  Verify that `myreviews.bookinfo` works as expected:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items..metadata.name}' --context=$CTX_CLUSTER2) -c sleep --context=$CTX_CLUSTER2 -- curl myreviews.bookinfo:9080/reviews/0
    {"id": "0","reviews": [{  "reviewer": "Reviewer1",  "text": "An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!", "rating": {"stars": 5, "color": "red"}},{  "reviewer": "Reviewer2",  "text": "Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.", "rating": {"stars": 4, "color": "red"}}]}
    {{< /text >}}

## Deploy private gateways for cross-cluster communication

### Generate certificates and keys for cluster1 and cluster2

{{< text bash >}}
$ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example.com/CN=Root CA' -keyout example.com.key -out example.com.crt
$ openssl req -subj '/O=example.com/CN=Root CA/L=c1.cluster.com' -out c1.example.com.csr -newkey rsa:2048 -nodes -keyout c1.example.com.key
$ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in c1.example.com.csr -out c1.example.com.crt
$ openssl req -subj '/O=example.com/CN=Root CA/L=c2.cluster.com' -out c2.example.com.csr -newkey rsa:2048 -nodes -keyout c2.example.com.key
$ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in c2.example.com.csr -out c2.example.com.crt
{{< /text >}}

### Deploy private egress gateway in cluster1

1.  Create `istio-private-gateways`:

    {{< text bash >}}
    $ kubernetes create namespace istio-private-gateways --context=$CTX_CLUSTER2
    {{< /text >}}

1. Create Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the client's and CA
   certificates.

    {{< text bash >}}
    $ kubectl create -n istio-private-gateways secret tls c1-client-certs --key c1.example.com.key --cert c1.example.com.crt
    $ kubectl create -n istio-private-gateways secret generic ca-certs --from-file=example.com.crt
    {{< /text >}}

1.  Generate the `istio-egressgateway` deployment with a volume to be mounted from the new secrets. Use the same options
    you used for generating your `istio.yaml`:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio/ --name istio --namespace istio-system -x charts/gateways/templates/deployment.yaml --set gateways.istio-ingressgateway.enabled=false \
    --set gateways.istio-egressgateway.enabled=true \
    --set 'gateways.istio-egressgateway.secretVolumes[0].name'=egressgateway-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[0].secretName'=istio-egressgateway-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[0].mountPath'=/etc/istio/egressgateway-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[1].name'=egressgateway-ca-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[1].secretName'=istio-egressgateway-ca-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[1].mountPath'=/etc/istio/egressgateway-ca-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[2].name'=nginx-client-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[2].secretName'=nginx-client-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[2].mountPath'=/etc/nginx-client-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[3].name'=nginx-ca-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[3].secretName'=nginx-ca-certs \
    --set 'gateways.istio-egressgateway.secretVolumes[3].mountPath'=/etc/nginx-ca-certs > \
    ./istio-egressgateway.yaml
    {{< /text >}}

1.  Redeploy `istio-egressgateway`:

    {{< text bash >}}
    $ kubectl apply -f ./istio-egressgateway.yaml
    deployment "istio-egressgateway" configured
    {{< /text >}}

1.  Verify that the key and the certificate are successfully loaded in the `istio-egressgateway` pod:

    {{< text bash >}}
    $ kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=egressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/nginx-client-certs /etc/nginx-ca-certs
    {{< /text >}}

    `tls.crt` and `tls.key` should exist in `/etc/istio/nginx-client-certs`, while `ca-chain.cert.pem` in
    `/etc/istio/nginx-ca-certs`.

### Deploy private ingress gateway in cluster2

## Expose and consume services

### Expose reviews v2

### Consume reviews v2

### Expose details

### Consume details

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

---
title: Mesh Federation
subtitle: Connect multiple service meshes ad-hoc, with limited service exposure and cross-cluster traffic control
description: Connect multiple service meshes ad-hoc, with limited service exposure and cross-cluster traffic control.
publishdate: 2019-08-08
attribution: Vadim Eisenberg (IBM)
keywords: [traffic-management,multicluster,security,gateway,tls]
---

Managing applications across multiple Kubernetes clusters is currently one of the hottest topics in Kubernetes and Istio
communities. You may need to split your applications between multiple clusters for the many different reasons:

-  scalability limits of a single cluster
-  separation of production/dev/test/staging environments
-  different security and compliance requirements for different parts of the application

And it is just a partial list.

Currently there are [three patterns](https://istio.io/docs/setup/kubernetes/install/multicluster/) in Istio to create a
[multicluster service mesh](/docs/concepts/multicluster-deployments/#multicluster-service-mesh).
A _multicluster service mesh_ is a single _logical_ service mesh, spread among multiple Kubernetes clusters.

Such a service mesh has the following characteristics:

- **uniform identical naming** of namespaces and services. The `withdraw` service in the `accounts` namespace in one
cluster has the same functionality and API as the `withdraw` service in the `accounts` namespace in all other clusters
in the mesh.
- **expose-all by default**. All the services are exposed by default to all the clusters in the mesh.
- **common identity and common trust** are established between all the clusters in the mesh.

The three patterns differ by the following aspects:

- The clusters are on a **single network** or on **multiple networks**. Single network means that the pods in one
cluster can reach the pods in other clusters directly. Multiple networks means that the pods in one cluster can reach
the pods in other clusters in the mesh only through their ingress gateways.
- The Istio control planes are **shared** between the clusters in the mesh or each cluster has its own **dedicated**
control plane.

There are use cases when you want to connect service meshes in separate clusters while limiting exposure of services
from one cluster to other clusters. You may want strict control of which clusters may consume specific services of the
exposing cluster.
Sometimes different clusters are operated by different organizations that do not have common naming rules and didn't
establish common trust. The Istio community has not yet decided on the right name for such a loosely-coupled
connection between independent service meshes. One of the proposed names is _mesh federation_. While I use this name in
this blog post, I do not claim that it is the best name for this pattern.

In this blog post I describe requirements for _mesh federation_ and propose a possible solution for it. I don't claim
that this is the best solution, the goal of the blog post is to share it with the community and the users, to get their
feedback.

## Requirements for mesh federation

- **non-uniform naming**. The `withdraw` service in the `accounts` namespace in one cluster might have
different functionality and API as the `withdraw` services in the `accounts` namespace in other clusters.
- **expose-nothing by default**. None of the services in a cluster are exposed by default, the cluster owners must
explicitly specify which services are exposed.
- **access control at the ingress gateway**. The access control of the traffic must be enforced at the ingress gateway,
forbidden traffic should not enter the cluster. This requirement implements [Defense-in-depth principle](https://en.wikipedia.org/wiki/Defense_in_depth_(computing)) and is part of
some compliance standards.
- **common trust may not exist**. The Istio sidecars in one cluster may not trust the Citadel certificates in other
cluster.

## The proposed implementation

I propose to base the implementation of mesh federation on the following principles:

- use **standard Istio mechanisms** such as gateways, virtual services, destination rules, RBAC
- use **standard Istio installations**, no specific support for mesh federation is required
- **ad-hoc cluster _pairing_** at any time. The owners of the clusters can install Istio and operate it independently,
  and decide to connect the clusters at some later point in time.
- **private gateways for cross-cluster communication**, with special certificates/private keys. Only the gateways trust
  each other, there is no trust between sidecars from different clusters

In the following sections I demonstrate mesh federation using two clusters and the Istio
[Bookinfo](/docs/examples/bookinfo/) application as an example.

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

    Access the web page of the Bookinfo application and verify that the reviews appear without stars, which means that
    the _v1_ version of _reviews_ is used.

1.  Delete the deployments of `reviews v2`, `reviews v3` and `ratings v1`:

    {{< text bash >}}
    $ kubectl delete deployment reviews-v2 reviews-v3 ratings-v1 --context=$CTX_CLUSTER1
    deployment.extensions "reviews-v2" deleted
    deployment.extensions "reviews-v3" deleted
    deployment.extensions "ratings-v1" deleted
    {{< /text >}}

    Access the webpage of the Bookinfo application and verify that it continues to work as before.

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
    $ kubectl apply --context=$CTX_CLUSTER2 -l app=reviews,version=v2 -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    $ kubectl apply --context=$CTX_CLUSTER2 -l app=reviews,version=v3 -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    $ kubectl apply --context=$CTX_CLUSTER2 -l service=reviews -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    $ kubectl apply --context=$CTX_CLUSTER2 -l app=ratings -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    serviceaccount/bookinfo-details created
    serviceaccount/bookinfo-ratings created
    serviceaccount/bookinfo-reviews created
    serviceaccount/bookinfo-productpage created
    deployment.apps/reviews-v2 created
    deployment.apps/reviews-v3 created
    service/reviews created
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

1.  Create a service for reviews. Call it `myreviews`, to demonstrate that you can use different names for services in
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

1.  Delete the `reviews` service (`myreviews` will be used instead):

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER2 -l service=reviews -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    service "reviews" deleted
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
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items..metadata.name}' --context=$CTX_CLUSTER2) -c sleep --context=$CTX_CLUSTER2 -- curl myreviews.bookinfo:9080/reviews/0 -w "\nResponse code: %{http_code}\n"
    {"id": "0","reviews": [{  "reviewer": "Reviewer1",  "text": "An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!", "rating": {"stars": 5, "color": "red"}},{  "reviewer": "Reviewer2",  "text": "Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.", "rating": {"stars": 4, "color": "red"}}]}
    Response code: 200
    {{< /text >}}

The following diagram shows the state of the clusters after deploying the Bookinfo services:

{{< image width="100%" link="./MeshFederation1_bookinfo.svg" caption="Two clusters after initial setup" >}}

## Deploy private gateways for cross-cluster communication (one-time setup)

In this section you create certificates and keys for `cluster1` and `cluster2` and deploy an egress gateway in `cluster1`
and an ingress gateway in `cluster2`. You mount the certificates and the keys to the gateways to establish trust between
the gateways. Note that only the gateways trust each other, there is no trust between workloads in the different
clusters.
These gateways could be different from the public gateways you use to control
[ingress](/docs/tasks/traffic-management/ingress/secure-ingress-mount/)
and
[egress](/docs/tasks/traffic-management/egress/egress-gateway/)
traffic
from and to the public Internet. You may want to deploy them on a private network of your
organization (or of your cloud provider) to reduce the possibilities for attacks from the public Internet. You may want
to use these gateways for cross-cluster communication only.

In this blog post you use non-existent hostnames, `c1.example.com`, `c2.example.com` and `c3.example.com`, as the
hostnames of three clusters. You do not deploy a third cluster in this blog post, only use its identity for testing RBAC policies.

### Generate certificates and keys for both clusters

You can use the command of your choice to generate certificates and keys, the command below use
[openssl](https://man.openbsd.org/openssl.1).

1.  Create an `openssl` configuration file for `cluster1`:

    {{< text bash >}}
    $ cat > ./certificate1.conf <<EOF
    [ req ]
    encrypt_key = no
    prompt = no
    utf8 = yes
    default_md = sha256
    req_extensions = req_ext
    x509_extensions = req_ext
    distinguished_name = req_dn
    [ req_ext ]
    subjectKeyIdentifier = hash
    basicConstraints = critical, CA:false
    keyUsage = critical, digitalSignature, nonRepudiation
    extendedKeyUsage = clientAuth
    subjectAltName = critical, @san
    [req_dn]
    O=example Inc., department 1
    CN=c1.example.com
    [ san ]
    URI.1 = spiffe://c1.example.com/istio-private-egressgateway
    EOF
    {{< /text >}}

1.  Create a configuration file for `cluster2`:

    {{< text bash >}}
    $ cat > ./certificate2.conf <<EOF
    [ req ]
    encrypt_key = no
    prompt = no
    utf8 = yes
    default_md = sha256
    req_extensions = req_ext
    x509_extensions = req_ext
    distinguished_name = req_dn
    [ req_ext ]
    subjectKeyIdentifier = hash
    basicConstraints = critical, CA:false
    keyUsage = critical, digitalSignature, nonRepudiation
    extendedKeyUsage = serverAuth
    subjectAltName = critical, @san
    [req_dn]
    O=example Inc., department 2
    CN=c2.example.com
    [ san ]
    URI.1 = spiffe://c2.example.com/istio-private-ingressgateway
    EOF
    {{< /text >}}

1.  Create a configuration file for `cluster3`. You do not deploy a third cluster in this blog post, only use the
    certificate and key of `cluster3` for testing RBAC policies.

    {{< text bash >}}
    $ cat > ./certificate3.conf <<EOF
    [ req ]
    encrypt_key = no
    prompt = no
    utf8 = yes
    default_md = sha256
    req_extensions = req_ext
    x509_extensions = req_ext
    distinguished_name = req_dn
    [ req_ext ]
    subjectKeyIdentifier = hash
    basicConstraints = critical, CA:false
    keyUsage = critical, digitalSignature, nonRepudiation
    extendedKeyUsage = clientAuth
    subjectAltName = critical, @san
    [req_dn]
    O=example Inc., department 3
    CN=c3.example.com
    [ san ]
    URI.1 = spiffe://c3.example.com/istio-private-egressgateway
    EOF
    {{< /text >}}

1.  Create the certificates and the keys:

    {{< text bash >}}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
    $ openssl req -reqexts req_ext -out c1.example.com.csr -newkey rsa:2048 -nodes -keyout c1.example.com.key -config ./certificate1.conf
    $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in c1.example.com.csr -out c1.example.com.crt -extensions req_ext -extfile ./certificate1.conf
    $ openssl req -reqexts req_ext -out c2.example.com.csr -newkey rsa:2048 -nodes -keyout c2.example.com.key -config ./certificate2.conf
    $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in c2.example.com.csr -out c2.example.com.crt -extensions req_ext -extfile ./certificate2.conf
    $ openssl req -reqexts req_ext -out c3.example.com.csr -newkey rsa:2048 -nodes -keyout c3.example.com.key -config ./certificate3.conf
    $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 2 -in c3.example.com.csr -out c3.example.com.crt -extensions req_ext -extfile ./certificate3.conf
    {{< /text >}}

### Deploy a private egress gateway in the first cluster

1.  Create the `istio-private-gateways` namespace:

    {{< text bash >}}
    $ kubectl create namespace istio-private-gateways --context=$CTX_CLUSTER1
    {{< /text >}}

1. Create Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the gateways's
   certificates and keys.

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 -n istio-private-gateways secret tls c1-example-com-certs --key c1.example.com.key --cert c1.example.com.crt
    $ kubectl create --context=$CTX_CLUSTER1 -n istio-private-gateways secret generic example-com-ca-certs --from-file=example.com.crt
    {{< /text >}}

1.  Deploy a private egress gateway and mount the new secrets as data volumes by the following command:

    {{< text bash >}}
    $ cat <<EOF | helm template install/kubernetes/helm/istio/ --name istio --namespace istio-private-gateways -x charts/gateways/templates/deployment.yaml -x charts/gateways/templates/service.yaml -x charts/gateways/templates/serviceaccount.yaml -x charts/gateways/templates/autoscale.yaml -x charts/gateways/templates/role.yaml -x charts/gateways/templates/rolebindings.yaml --set global.istioNamespace=istio-system -f - | kubectl apply --context=$CTX_CLUSTER1 -f -
    gateways:
      enabled: true
      istio-egressgateway:
        enabled: false
      istio-ingressgateway:
        enabled: false
      istio-private-egressgateway:
        enabled: true
        labels:
          app: istio-private-egressgateway
          istio: private-egressgateway
        replicaCount: 1
        autoscaleMin: 1
        autoscaleMax: 5
        cpu:
          targetAverageUtilization: 80
        type: ClusterIP
        ports:
        - port: 80
          name: http
        - port: 443
          name: https
        secretVolumes:
        - name: c1-example-com-certs
          secretName: c1-example-com-certs
          mountPath: /etc/istio/c1.example.com/certs
        - name: example-com-ca-certs
          secretName: example-com-ca-certs
          mountPath: /etc/istio/example.com/certs
    EOF
    {{< /text >}}

1.  Verify that the egress gateway's pod is running:

    {{< text bash >}}
    $ kubectl get pods $(kubectl get pod -l istio=private-egressgateway -n istio-private-gateways -o jsonpath='{.items..metadata.name}' --context=$CTX_CLUSTER1)  -n istio-private-gateways --context=$CTX_CLUSTER1
    NAME                                           READY   STATUS    RESTARTS   AGE
    istio-private-egressgateway-586c8cb5db-5m77h   1/1     Running   0          43s
    {{< /text >}}

1.  Verify that the key and the certificates are successfully loaded in the egress gateway's pod:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=private-egressgateway -n istio-private-gateways -o jsonpath='{.items..metadata.name}' --context=$CTX_CLUSTER1)  -n istio-private-gateways --context=$CTX_CLUSTER1 -- ls -al /etc/istio/c1.example.com/certs /etc/istio/example.com/certs
    /etc/istio/c1.example.com/certs:
    total 4
    drwxrwxrwt 3 root root  120 Jul 29 00:27 .
    drwxr-xr-x 3 root root 4096 Jul 29 00:27 ..
    drwxr-xr-x 2 root root   80 Jul 29 00:27 ..2019_07_29_00_27_05.153388454
    lrwxrwxrwx 1 root root   31 Jul 29 00:27 ..data -> ..2019_07_29_00_27_05.153388454
    lrwxrwxrwx 1 root root   14 Jul 29 00:27 tls.crt -> ..data/tls.crt
    lrwxrwxrwx 1 root root   14 Jul 29 00:27 tls.key -> ..data/tls.key

    /etc/istio/example.com/certs:
    total 4
    drwxrwxrwt 3 root root  100 Jul 29 00:27 .
    drwxr-xr-x 3 root root 4096 Jul 29 00:27 ..
    drwxr-xr-x 2 root root   60 Jul 29 00:27 ..2019_07_29_00_27_05.678454477
    lrwxrwxrwx 1 root root   31 Jul 29 00:27 ..data -> ..2019_07_29_00_27_05.678454477
    lrwxrwxrwx 1 root root   22 Jul 29 00:27 example.com.crt -> ..data/example.com.crt
    {{< /text >}}

### Deploy a private ingress gateway in the second cluster

1.  Create the `istio-private-gateways` namespace:

    {{< text bash >}}
    $ kubectl create namespace istio-private-gateways --context=$CTX_CLUSTER2
    {{< /text >}}

1.  Create Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the gateways's
    certificates and keys.

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 -n istio-private-gateways secret tls c2-example-com-certs --key c2.example.com.key --cert c2.example.com.crt
    $ kubectl create --context=$CTX_CLUSTER2 -n istio-private-gateways secret generic example-com-ca-certs --from-file=example.com.crt
    {{< /text >}}

1.  Deploy a private ingress gateway and mount the new secrets as data volumes by the following command:

    {{< text bash >}}
    $ cat <<EOF | helm template install/kubernetes/helm/istio/ --name istio --namespace istio-private-gateways -x charts/gateways/templates/deployment.yaml -x charts/gateways/templates/service.yaml -x charts/gateways/templates/serviceaccount.yaml -x charts/gateways/templates/autoscale.yaml -x charts/gateways/templates/role.yaml -x charts/gateways/templates/rolebindings.yaml --set global.istioNamespace=istio-system -f - | kubectl apply --context=$CTX_CLUSTER2 -f -
    gateways:
      enabled: true
      istio-egressgateway:
        enabled: false
      istio-ingressgateway:
        enabled: false
      istio-private-ingressgateway:
        enabled: true
        labels:
          app: istio-private-ingressgateway
          istio: private-ingressgateway
        replicaCount: 1
        autoscaleMin: 1
        autoscaleMax: 5
        cpu:
          targetAverageUtilization: 80
        type: LoadBalancer
        ports:
        - port: 15443
          name: https-for-cross-cluster-communication
        secretVolumes:
        - name: c2-example-com-certs
          secretName: c2-example-com-certs
          mountPath: /etc/istio/c2.example.com/certs
        - name: example-com-ca-certs
          secretName: example-com-ca-certs
          mountPath: /etc/istio/example.com/certs
    EOF
    {{< /text >}}

1.  Verify that the ingress gateway's pod is running:

    {{< text bash >}}
    $ kubectl get pods $(kubectl get pod -l istio=private-ingressgateway -n istio-private-gateways -o jsonpath='{.items..metadata.name}' --context=$CTX_CLUSTER2)  -n istio-private-gateways --context=$CTX_CLUSTER2
    NAME                                            READY   STATUS    RESTARTS   AGE
    istio-private-ingressgateway-546fccbcdd-2w8n7   1/1     Running   0          2m51s
    {{< /text >}}

1.  Verify that the key and the certificate are successfully loaded in the ingress gateway's pod:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=private-ingressgateway -n istio-private-gateways -o jsonpath='{.items..metadata.name}' --context=$CTX_CLUSTER2)  -n istio-private-gateways --context=$CTX_CLUSTER2 -- ls -al /etc/istio/c2.example.com/certs /etc/istio/example.com/certs
    /etc/istio/c2.example.com/certs:
    total 4
    drwxrwxrwt 3 root root  120 Jul 29 00:35 .
    drwxr-xr-x 3 root root 4096 Jul 29 00:35 ..
    drwxr-xr-x 2 root root   80 Jul 29 00:35 ..2019_07_29_00_35_10.417805046
    lrwxrwxrwx 1 root root   31 Jul 29 00:35 ..data -> ..2019_07_29_00_35_10.417805046
    lrwxrwxrwx 1 root root   14 Jul 29 00:35 tls.crt -> ..data/tls.crt
    lrwxrwxrwx 1 root root   14 Jul 29 00:35 tls.key -> ..data/tls.key

    /etc/istio/example.com/certs:
    total 4
    drwxrwxrwt 3 root root  100 Jul 29 00:35 .
    drwxr-xr-x 3 root root 4096 Jul 29 00:35 ..
    drwxr-xr-x 2 root root   60 Jul 29 00:35 ..2019_07_29_00_35_10.932595677
    lrwxrwxrwx 1 root root   31 Jul 29 00:35 ..data -> ..2019_07_29_00_35_10.932595677
    lrwxrwxrwx 1 root root   22 Jul 29 00:35 example.com.crt -> ..data/example.com.crt
    {{< /text >}}

The following diagram shows the state of the clusters after deploying the private gateways:

{{< image width="100%" link="./MeshFederation2_bookinfo.svg" caption="Two clusters after deploying private gateways" >}}

## Expose and consume services (on a per-service basis)

Once you create the private gateways, you can start exposing services in one cluster and consume them in another
cluster. Note that by default no service is exposed, the cluster owners must specify explicitly which service they want
to expose. They can cancel the exposure at any point if they want.

### Expose reviews v2 in the second cluster

1.  Define an ingress `Gateway`:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER2 -n istio-private-gateways -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-private-ingressgateway
    spec:
      selector:
        istio: private-ingressgateway
      servers:
      - port:
          number: 15443
          name: https
          protocol: HTTPS
        tls:
          mode: MUTUAL
          serverCertificate: /etc/istio/c2.example.com/certs/tls.crt
          privateKey: /etc/istio/c2.example.com/certs/tls.key
          caCertificates: /etc/istio/example.com/certs/example.com.crt
        hosts:
        - c2.example.com
    EOF
    {{< /text >}}

1.  Configure routing to `reviews v2`:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER2 -n istio-private-gateways -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: privately-exposed-services
    spec:
      hosts:
      - c2.example.com
      gateways:
      - istio-private-ingressgateway
      http:
      - match:
        - uri:
            prefix: /bookinfo/myreviews/v2/
        rewrite:
          uri: /
          authority: myreviews.bookinfo.svc.cluster.local
        route:
        - destination:
            port:
              number: 9080
            subset: v2
            host: myreviews.bookinfo.svc.cluster.local
    EOF
    {{< /text >}}

1.  Execute the following command to determine if your Kubernetes cluster is running in an environment that supports
   external load balancers:

    {{< text bash >}}
    $ kubectl get svc istio-private-ingressgateway -n istio-private-gateways --context=$CTX_CLUSTER2
    NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                      AGE
    istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121  80:31380/TCP,443:31390/TCP,31400:31400/TCP   17h
    {{< /text >}}

    If the `EXTERNAL-IP` value is set, your environment has an external load balancer that you can use for the ingress gateway.
    If the `EXTERNAL-IP` value is `<none>` (or perpetually `<pending>`), your environment does not provide an external load balancer for the ingress gateway.
    In this case, you can access the gateway using the service's [node port](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport).

    Set the private ingress IP and ports:

    {{< text bash >}}
    $ export CLUSTER2_INGRESS_HOST=$(kubectl -n istio-private-gateways get service istio-private-ingressgateway --context=$CTX_CLUSTER2 -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ export CLUSTER2_SECURE_INGRESS_PORT=$(kubectl -n istio-private-gateways get service istio-private-ingressgateway --context=$CTX_CLUSTER2 -o jsonpath='{.spec.ports[?(@.name=="https-for-cross-cluster-communication")].port}')
    {{< /text >}}

1.  Test your configuration by accessing the exposed service. The `curl` command below uses the certificates of
    `cluster1`:

    {{< text bash >}}
    $ curl -HHost:c2.example.com --resolve c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT:$CLUSTER2_INGRESS_HOST --cacert example.com.crt --key c1.example.com.key --cert c1.example.com.crt https://c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT/bookinfo/myreviews/v2/reviews/0 -w "\nResponse code: %{http_code}\n"
    {"id": "0","reviews": [{  "reviewer": "Reviewer1",  "text": "An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!", "rating": {"stars": 5, "color": "black"}},{  "reviewer": "Reviewer2",  "text": "Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.", "rating": {"stars": 4, "color": "black"}}]}
    Response code: 200
    {{< /text >}}

### Consume reviews v2 in the first cluster

Bind reviews exposed from `cluster2` as `reviews.default.svc.cluster.local` in `cluster1`.

1.  Create a Kubernetes service for `c2.example.com` since it is not an existing hostname. In the real life, you
    would use the real hostname of your cluster.

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -n istio-private-gateways -f - <<EOF
    kind: Service
    apiVersion: v1
    metadata:
      name: c2-example-com
    spec:
      ports:
      - protocol: TCP
        port: 15443
    EOF
    {{< /text >}}

1.  Create an endpoint for `c2.example.com`:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -n istio-private-gateways -f - <<EOF
    kind: Endpoints
    apiVersion: v1
    metadata:
      name: c2-example-com
    subsets:
      - addresses:
          - ip: $CLUSTER2_INGRESS_HOST
        ports:
          - port: 15443
    EOF
    {{< /text >}}

1.  Create a destination rule for `c2.example.com`:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -n istio-private-gateways -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: c2-example-com
    spec:
      host: c2-example-com
      exportTo:
      - "."
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 15443
          tls:
            mode: MUTUAL
            clientCertificate: /etc/istio/c1.example.com/certs/tls.crt
            privateKey: /etc/istio/c1.example.com/certs/tls.key
            caCertificates: /etc/istio/example.com/certs/example.com.crt
            sni: c2.example.com
    EOF
    {{< /text >}}

1.  Create an egress `Gateway` for `reviews.default.svc.cluster.local`, port 443, and a destination rule for
    traffic directed to the egress gateway.

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -n istio-private-gateways -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-private-egressgateway
    spec:
      selector:
        istio: private-egressgateway
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        hosts:
        - reviews.default.svc.cluster.local
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: istio-private-egressgateway-reviews-default
    spec:
      host: istio-private-egressgateway.istio-private-gateways.svc.cluster.local
      subsets:
      - name: reviews-default
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 443
            tls:
              mode: ISTIO_MUTUAL
              sni: reviews.default.svc.cluster.local
    EOF
    {{< /text >}}

1.  Define a `VirtualService` to direct traffic from the egress gateway
    to the external service:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -n istio-private-gateways -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: reviews
    spec:
      hosts:
      - reviews.default.svc.cluster.local
      gateways:
      - istio-private-egressgateway.istio-private-gateways
      http:
      - match:
          - port: 443
            uri:
              prefix: /
            gateways:
            - istio-private-egressgateway.istio-private-gateways
        rewrite:
          uri: /bookinfo/myreviews/v2/
          authority: c2.example.com
        route:
        - destination:
            host: c2-example-com.istio-private-gateways.svc.cluster.local
            port:
              number: 15443
          weight: 100
    EOF
    {{< /text >}}

1.  Now you can perform a canary release for `reviews v2`.
    Define a virtual service to direct the traffic from sidecars to the egress gateway for the `jason` user:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: reviews
    spec:
      hosts:
      - reviews
      http:
      - match:
        - port: 9080
          headers:
            end-user:
              exact: jason
        rewrite:
          authority: reviews.default.svc.cluster.local
        route:
        - destination:
            host: istio-private-egressgateway.istio-private-gateways.svc.cluster.local
            subset: reviews-default
            port:
              number: 443
      - match:
        - port: 9080
        route:
        - destination:
            host: reviews
            subset: v1
          weight: 100
    EOF
    {{< /text >}}

1.  Use the _Sign in_ button in the top right corner to sign in as `jason` (any password would do).
    You will see that now the ratings with black starts appear which means that the remote version is used.

1.  Sign out and see that for the rest of the users the local version is used.

1.  Perform load balancing 50:50 between your local version of reviews (v1) and the remote version of reviews (v2):

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - match:
    - port: 9080
    rewrite:
      authority: reviews.default.svc.cluster.local
    route:
    - destination:
        host: reviews
        subset: v1
        port:
          number: 9080
      weight: 50
    - destination:
        host: istio-private-egressgateway.istio-private-gateways.svc.cluster.local
        subset: reviews-default
        port:
          number: 443
      weight: 50
EOF
{{< /text >}}

1.  Refresh your app webpage and see reviews with black stars appear roughly 50% of the time.

The following diagram shows the state of the clusters after configuring exposing and consuming of the `reviews` service:

{{< image width="100%" link="./MeshFederation3_bookinfo.svg" caption="Two clusters after configuring exposing and consuming the reviews service" >}}

### Deploy `reviews v2` locally and retire `reviews v1`

1.  Deploy `reviews v2` locally:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -l app=reviews,version=v2 -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    {{< /text >}}

1.  Direct all the traffic to the local version `reviews v2`:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: reviews
    spec:
      hosts:
      - reviews
      http:
      - match:
        - port: 9080
        route:
        - destination:
            host: reviews.default.svc.cluster.local
            subset: v2
          weight: 100
    EOF
    {{< /text >}}

1.  Delete the consumption of the remote service from `cluster2`:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER1 virtualservice reviews -n istio-private-gateways
    $ kubectl delete --context=$CTX_CLUSTER1 destinationrule istio-private-egressgateway-reviews-default -n istio-private-gateways
    $ kubectl delete --context=$CTX_CLUSTER1 gateway istio-private-egressgateway -n istio-private-gateways
    {{< /text >}}

1.  Delete the deployments of `reviews v1`:

    {{< text bash >}}
    $ kubectl delete deployment reviews-v1 --context=$CTX_CLUSTER1
    deployment.extensions "reviews-v1" deleted
    {{< /text >}}

1.  Check the pods:

    {{< text bash >}}
    $ kubectl get pods --context=$CTX_CLUSTER1
    details-v1-59489d6fb6-m5s5j       2/2     Running   0          4h31m
    productpage-v1-689ff955c6-7qsk6   2/2     Running   0          4h31m
    reviews-v1-657b76fc99-lx46g       2/2     Running   0          4h31m
    sleep-57f9d6fd6b-px97z            2/2     Running   0          4h31m
    {{< /text >}}

    You should have three pods of the Bookinfo application and a pod for the sleep testing app.

1.  Access the web page of the Bookinfo application. Notice the `Ratings service is currently unavailable` error. This
    is because the `ratings` service in a remote cluster and you neither exposed it in `cluster2` nor configured
    consuming it in `cluster1`. You will do it in the next sections.

    The current deployment of the services in the two clusters is shown below:

    {{< image width="100%" link="./MeshFederation4_bookinfo.svg" caption="Two clusters after deploying reviews v2 in cluster1" >}}

### Expose ratings and reviews v3

1.  Redefine the `privately-exposed-services` virtual service you created earlier, to perform routing to `reviews v3`
    and `ratings`, and to stop routing to `reviews v2`

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER2 -n istio-private-gateways -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: privately-exposed-services
    spec:
      hosts:
      - c2.example.com
      gateways:
      - istio-private-ingressgateway
      http:
      - match:
        - uri:
            prefix: /bookinfo/myreviews/v3/
        rewrite:
          uri: /
          authority: myreviews.bookinfo.svc.cluster.local
        route:
        - destination:
            port:
              number: 9080
            subset: v3
            host: myreviews.bookinfo.svc.cluster.local
      - match:
        - uri:
            prefix: /bookinfo/ratings/v1/
        rewrite:
          uri: /
          authority: ratings.bookinfo.svc.cluster.local
        route:
        - destination:
            port:
              number: 9080
            subset: v1
            host: ratings.bookinfo.svc.cluster.local
    EOF
    {{< /text >}}

    Test your configuration by performing the commands below:

1.  Access `reviews v3` from your local machine:

    {{< text bash >}}
    $ curl -HHost:c2.example.com --resolve c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT:$CLUSTER2_INGRESS_HOST --cacert example.com.crt --key c1.example.com.key --cert c1.example.com.crt https://c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT/bookinfo/myreviews/v3/reviews/0 -w "\nResponse code: %{http_code}\n"
    {"id": "0","reviews": [{  "reviewer": "Reviewer1",  "text": "An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!", "rating": {"stars": 5, "color": "red"}},{  "reviewer": "Reviewer2",  "text": "Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.", "rating": {"stars": 4, "color": "red"}}]}
    Response code: 200
    {{< /text >}}

1.  Access `ratings`:

    {{< text bash >}}
    $ curl -HHost:c2.example.com --resolve c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT:$CLUSTER2_INGRESS_HOST --cacert example.com.crt --key c1.example.com.key --cert c1.example.com.crt https://c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT/bookinfo/ratings/v1/ratings/0 -w "\nResponse code: %{http_code}\n"
    {"id":0,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    Response code: 200
    {{< /text >}}

1.  Try to access `reviews v2`, it should not be accessible anymore:

    {{< text bash >}}
    $ curl -HHost:c2.example.com --resolve c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT:$CLUSTER2_INGRESS_HOST --cacert example.com.crt --key c1.example.com.key --cert c1.example.com.crt https://c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT/bookinfo/myreviews/v2/reviews/0 -w "\nResponse code: %{http_code}\n"
    Response code: 404
    {{< /text >}}

### Consume ratings and reviews v3

1.  Note that in this case the local version of the `reviews` service issues requests to the `ratings`, which does not
    exist locally. In this case you must handle:
    1. The DNS should have an entry for `ratings.default.svc.cluster.local`. Otherwise the local `reviews` service will
    fail at DNS query.
    1. Routing to the remote `ratings` service

    To handle DNS, create a Kubernetes service for `ratings.default.svc.cluster.local`. Handle routing to the remote
    `ratings` service, and also to `reviews v3` in the steps that follow after the next step.

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
    kind: Service
    apiVersion: v1
    metadata:
      name: ratings
    spec:
      type: ExternalName
      externalName: istio-private-egressgateway.istio-private-gateways.svc.cluster.local
      ports:
      - name: http
        protocol: TCP
        port: 9080
    EOF
    {{< /text >}}

1.  Create an egress `Gateway` for `ratings.default.svc.cluster.local` and `reviews.default.svc.cluster.local`, port 80,
    and destination rules for traffic directed to the egress gateway.

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -n istio-private-gateways -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-private-egressgateway
    spec:
      selector:
        istio: private-egressgateway
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        hosts:
        - reviews.default.svc.cluster.local
        - ratings.default.svc.cluster.local
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: istio-private-egressgateway-reviews-default
    spec:
      host: istio-private-egressgateway.istio-private-gateways.svc.cluster.local
      subsets:
      - name: reviews-default
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 443
            tls:
              mode: ISTIO_MUTUAL
              sni: reviews.default.svc.cluster.local
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: istio-private-egressgateway-ratings-default
    spec:
      host: istio-private-egressgateway.istio-private-gateways.svc.cluster.local
      subsets:
      - name: ratings-default
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 443
            tls:
              mode: ISTIO_MUTUAL
              sni: ratings.default.svc.cluster.local
    EOF
    {{< /text >}}

1.  Define a `VirtualService` to direct traffic from the egress gateway
    to `ratings`:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -n istio-private-gateways -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: ratings
    spec:
      hosts:
      - ratings.default.svc.cluster.local
      gateways:
      - istio-private-egressgateway.istio-private-gateways
      http:
      - match:
          - port: 443
            uri:
              prefix: /
            gateways:
            - istio-private-egressgateway.istio-private-gateways
        rewrite:
          uri: /bookinfo/ratings/v1/
          authority: c2.example.com
        route:
        - destination:
            host: c2-example-com.istio-private-gateways.svc.cluster.local
            port:
              number: 15443
          weight: 100
    EOF
    {{< /text >}}

1.  Define a `VirtualService` to direct traffic from the egress gateway
    to `reviews-v3`:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -n istio-private-gateways -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: reviews
    spec:
      hosts:
      - reviews.default.svc.cluster.local
      gateways:
      - istio-private-egressgateway.istio-private-gateways
      http:
      - match:
          - port: 443
            uri:
              prefix: /
            gateways:
            - istio-private-egressgateway.istio-private-gateways
        rewrite:
          uri: /bookinfo/myreviews/v3/
          authority: c2.example.com
        route:
        - destination:
            host: c2-example-com.istio-private-gateways.svc.cluster.local
            port:
              number: 15443
          weight: 100
    EOF
    {{< /text >}}

1.  Direct traffic destined to `ratings` to the egress gateway:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: ratings
    spec:
      hosts:
      - ratings
      http:
      - match:
        - port: 9080
        rewrite:
          authority: ratings.default.svc.cluster.local
        route:
        - destination:
            host: istio-private-egressgateway.istio-private-gateways.svc.cluster.local
            subset: ratings-default
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1.  Access the webpage of your application and verify that the ratings are now displayed correctly, with black stars.

1.  Perform load balancing 50:50 between your local version of reviews (v2) and the remote version of reviews (v3):

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: reviews
    spec:
      hosts:
      - reviews
      http:
      - match:
        - port: 9080
        rewrite:
          authority: reviews.default.svc.cluster.local
        route:
        - destination:
            host: reviews
            subset: v2
            port:
              number: 9080
          weight: 50
        - destination:
            host: istio-private-egressgateway.istio-private-gateways.svc.cluster.local
            subset: reviews-default
            port:
              number: 443
          weight: 50
    EOF
    {{< /text >}}

1.  Refresh your app webpage and see reviews with black and red stars appear roughly 50:50.

The following diagram shows the state of the clusters after configuring exposing and consuming of the `reviews v3`
and `ratings` services:

{{< image width="100%" link="./MeshFederation5_bookinfo.svg" caption="Two clusters after configuring exposing and consuming the ratings and reviews v3 services" >}}

### Cancel exposure of ratings

Let's consider a scenario where the owners of `cluster2` decide to stop exposure of the `ratings` service. They can do it in the following way:

1.  Remove routing to `ratings` in `cluster2` (leave routing to `reviews` only):

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER2 -n istio-private-gateways -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: privately-exposed-services
    spec:
      hosts:
      - c2.example.com
      gateways:
      - istio-private-ingressgateway
      http:
      - match:
        - uri:
            prefix: /bookinfo/myreviews/v3/
        rewrite:
          uri: /
          authority: myreviews.bookinfo.svc.cluster.local
        route:
        - destination:
            port:
              number: 9080
            subset: v3
            host: myreviews.bookinfo.svc.cluster.local
    EOF
    {{< /text >}}

1.  Access the webpage of your application and verify that instead of the black stars appear the
    `Ratings service is currently unavailable` message. The red stars are displayed correctly, since they are shown by
    `reviews v3` that runs in `cluster2` and has access to `ratings`.

1.  To expose the `ratings` back, run:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER2 -n istio-private-gateways -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: privately-exposed-services
    spec:
      hosts:
      - c2.example.com
      gateways:
      - istio-private-ingressgateway
      http:
      - match:
        - uri:
            prefix: /bookinfo/myreviews/v3/
        rewrite:
          uri: /
          authority: myreviews.bookinfo.svc.cluster.local
        route:
        - destination:
            port:
              number: 9080
            subset: v3
            host: myreviews.bookinfo.svc.cluster.local
      - match:
        - uri:
            prefix: /bookinfo/ratings/v1/
        rewrite:
          uri: /
          authority: ratings.bookinfo.svc.cluster.local
        route:
        - destination:
            port:
              number: 9080
            subset: v1
            host: ratings.bookinfo.svc.cluster.local
    EOF
    {{< /text >}}

## Apply Istio RBAC on `cluster2`

### Apply Istio RBAC on the `bookinfo` namespace

1.   Create Istio service roles for read access to `reviews` and `ratings`.

    {{< text bash >}}
    $ kubectl apply  --context=$CTX_CLUSTER2 -n bookinfo -f - <<EOF
    apiVersion: rbac.istio.io/v1alpha1
    kind: ServiceRole
    metadata:
      name: reviews-reader
    spec:
      rules:
      - services: ["myreviews.bookinfo.svc.cluster.local"]
        methods: ["GET"]
    ---
    apiVersion: rbac.istio.io/v1alpha1
    kind: ServiceRole
    metadata:
      name: ratings-reader
    spec:
      rules:
      - services: ["ratings.bookinfo.svc.cluster.local"]
        methods: ["GET"]
    EOF
    {{< /text >}}

1.  Create role bindings to enable read access to microservices according to the requirements of the application:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER2 -n bookinfo -f - <<EOF
    apiVersion: rbac.istio.io/v1alpha1
    kind: ServiceRoleBinding
    metadata:
      name: reviews-reader
    spec:
      subjects:
      - user: "cluster.local/ns/istio-private-gateways/sa/istio-private-ingressgateway-service-account"
      roleRef:
        kind: ServiceRole
        name: reviews-reader
    ---
    apiVersion: rbac.istio.io/v1alpha1
    kind: ServiceRoleBinding
    metadata:
      name: ratings-reader
    spec:
      subjects:
      - user: "cluster.local/ns/bookinfo/sa/bookinfo-reviews"
      - user: "cluster.local/ns/istio-private-gateways/sa/istio-private-ingressgateway-service-account"
      roleRef:
        kind: ServiceRole
        name: ratings-reader
    EOF
    {{< /text >}}

1.  Enable [Istio RBAC](/docs/concepts/security/#authorization) on the `bookinfo` namespace.

    {{< warning >}}
    If you have Istio RBAC already enabled on some of your namespaces, add `bookinfo` to the list of the included namespaces. The command below assumes that you do not have Istio RBAC in your cluster enabled.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER2 -f - <<EOF
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ClusterRbacConfig
    metadata:
      name: default
      namespace: istio-system
    spec:
      mode: ON_WITH_INCLUSION
      inclusion:
        namespaces: [ bookinfo ]
    EOF
    {{< /text >}}

1.  Access the application's webpage in `cluster` and verify that the application continues to work, which would mean that the
    authorized access is allowed and you configured your policy rules correctly.

1.  Check that unauthorized access is denied. Send a GET request from `ratings` to `reviews`:

    {{< text bash >}}
    $  kubectl exec -it $(kubectl get pod -l app=ratings --context=$CTX_CLUSTER2 -n bookinfo -o jsonpath='{.items[0].metadata.name}') --context=$CTX_CLUSTER2 -n bookinfo -c ratings -- curl myreviews:9080/reviews/0 -w "\nResponse code: %{http_code}\n"
    RBAC: access denied
    Response code: 403
    {{< /text >}}

### Enable RBAC on the ingress gateway

1.   Create Istio service role for read access to `istio-private-ingressgateway`:

    {{< text bash >}}
    $ kubectl apply  --context=$CTX_CLUSTER2 -n istio-private-gateways -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: private-ingress-rbac
    spec:
      workloadLabels:
        istio: private-ingressgateway
      filters:
      - filterName: envoy.filters.http.rbac
        filterType: HTTP
        listenerMatch:
          portNumber: 15443
          listenerType: GATEWAY
          listenerProtocol: HTTP
        filterConfig:
          rules:
            action: ALLOW
            policies:
              reviews_v3:
                permissions:
                  and_rules:
                    rules:
                    - header:
                        name: ":path"
                        prefix_match: "/bookinfo/myreviews/v3/"
                    - header:
                        name: ":method"
                        exact_match: "GET"
                principals:
                - authenticated:
                    principal_name:
                      exact: "spiffe://c1.example.com/istio-private-egressgateway"
              ratings_v1:
                permissions:
                  and_rules:
                    rules:
                    - header:
                        name: ":path"
                        prefix_match: "/bookinfo/ratings/v1/"
                    - header:
                        name: ":method"
                        exact_match: "GET"
                principals:
                - authenticated:
                    principal_name:
                      exact: "spiffe://c1.example.com/istio-private-egressgateway"
    EOF
    {{< /text >}}

1.  Refresh the webpage of your application and verify that everything is working as before.

1.  Let's change the RBAC policy to allow `reviews` to be exposed to the `c1` cluster while `ratings` will be exposed to
    the `c3` cluster:

    {{< text bash >}}
    $ kubectl apply  --context=$CTX_CLUSTER2 -n istio-private-gateways -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: private-ingress-rbac
    spec:
      workloadLabels:
        istio: private-ingressgateway
      filters:
      - filterName: envoy.filters.http.rbac
        filterType: HTTP
        listenerMatch:
          portNumber: 15443
          listenerType: GATEWAY
          listenerProtocol: HTTP
        filterConfig:
          rules:
            action: ALLOW
            policies:
              reviews_v3:
                permissions:
                  and_rules:
                    rules:
                    - header:
                        name: ":path"
                        prefix_match: "/bookinfo/myreviews/v3/"
                    - header:
                        name: ":method"
                        exact_match: "GET"
                principals:
                - authenticated:
                    principal_name:
                      exact: "spiffe://c1.example.com/istio-private-egressgateway"
              ratings_v1:
                permissions:
                  and_rules:
                    rules:
                    - header:
                        name: ":path"
                        prefix_match: "/bookinfo/ratings/v1/"
                    - header:
                        name: ":method"
                        exact_match: "GET"
                principals:
                - authenticated:
                    principal_name:
                      exact: "spiffe://c3.example.com/istio-private-egressgateway"
    EOF
    {{< /text >}}

1.  Refresh the webpage of your application multiple times. Note that the red stars appear as before, roughly 50% of
    time. For other 50% of time, the `Ratings service is currently unavailable` message is shown.

1.  Verify by `curl` that `reviews` is allowed for the `c1` cluster:

    {{< text bash >}}
    $ curl -HHost:c2.example.com --resolve c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT:$CLUSTER2_INGRESS_HOST --cacert example.com.crt --key c1.example.com.key --cert c1.example.com.crt https://c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT/bookinfo/myreviews/v3/reviews/0 -w "\nResponse code: %{http_code}\n"
    {"id": "0","reviews": [{  "reviewer": "Reviewer1",  "text": "An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!", "rating": {"stars": 5, "color": "red"}},{  "reviewer": "Reviewer2",  "text": "Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.", "rating": {"stars": 4, "color": "red"}}]}
    Response code: 200
    {{< /text >}}

1.  Verify by `curl` that `reviews` is denied for the `c3` cluster:

    {{< text bash >}}
    $ curl -HHost:c2.example.com --resolve c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT:$CLUSTER2_INGRESS_HOST --cacert example.com.crt --key c3.example.com.key --cert c3.example.com.crt https://c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT/bookinfo/myreviews/v3/reviews/0 -w "\nResponse code: %{http_code}\n"
    RBAC: access denied
    Response code: 403
    {{< /text >}}

1.  Verify by `curl` that `ratings` is denied for the `c1` cluster:

    {{< text bash >}}
    $ curl -HHost:c2.example.com --resolve c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT:$CLUSTER2_INGRESS_HOST --cacert example.com.crt --key c1.example.com.key --cert c1.example.com.crt https://c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT/bookinfo/ratings/v1/ratings/0 -w "\nResponse code: %{http_code}\n"
    RBAC: access denied
    Response code: 403
    {{< /text >}}

1.  Verify by `curl` that `ratings` is allowed for the `c3` cluster:

    {{< text bash >}}
    $ curl -HHost:c2.example.com --resolve c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT:$CLUSTER2_INGRESS_HOST --cacert example.com.crt --key c3.example.com.key --cert c3.example.com.crt https://c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT/bookinfo/ratings/v1/ratings/0 -w "\nResponse code: %{http_code}\n"
    {"id":0,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    Response code: 200
    {{< /text >}}

## Troubleshooting

1.  Enable Envoy access logs for `cluster1`:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --namespace=istio-system -x templates/configmap.yaml --set global.proxy.accessLogFile="/dev/stdout" | kubectl replace --context=$CTX_CLUSTER1 -f -
    {{< /text >}}

1.  Enable Envoy access logs for `cluster2`:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --namespace=istio-system -x templates/configmap.yaml --set global.proxy.accessLogFile="/dev/stdout" | kubectl replace --context=$CTX_CLUSTER2 -f -
    {{< /text >}}

1.  Check the logs of the private ingress gateway at `cluster2`:

    {{< text bash >}}
    $ kubectl logs -l istio=private-ingressgateway --context=$CTX_CLUSTER2 -n istio-private-gateways
    {{< /text >}}

1.  Check the logs of the private egress gateway at `cluster1`:

    {{< text bash >}}
    $ kubectl logs -l istio=private-egressgateway --context=$CTX_CLUSTER1 -n istio-private-gateways
    {{< /text >}}

1.  Check the logs of `productpage` at `cluster1`:

    {{< text bash >}}
    $ kubectl logs -l app=productpage -c istio-proxy --context=$CTX_CLUSTER1
    {{< /text >}}

1.  Check the logs of `reviews v2` at `cluster2`:

    {{< text bash >}}
    $ kubectl logs -l app=reviews,version=v2 -n bookinfo -c istio-proxy --context=$CTX_CLUSTER2
    {{< /text >}}

1.  Check the Istio configuration artifacts in `cluster1`:

    {{< text bash >}}
    $ kubectl get gw,vs,dr -n istio-private-gateways --context=$CTX_CLUSTER1
    {{< /text >}}

1.  Check the Istio configuration artifacts in `cluster2`:

    {{< text bash >}}
    $ kubectl get gw,vs,dr,envoyfilter -n istio-private-gateways --context=$CTX_CLUSTER2
    {{< /text >}}

## Cleanup

### Delete consumption of services in `cluster1`

{{< text bash >}}
$ kubectl delete --context=$CTX_CLUSTER1 virtualservice reviews -n istio-private-gateways
$ kubectl delete --context=$CTX_CLUSTER1 destinationrule istio-private-egressgateway-reviews-default -n istio-private-gateways
$ kubectl delete --context=$CTX_CLUSTER1 gateway istio-private-egressgateway -n istio-private-gateways
$ kubectl delete --context=$CTX_CLUSTER1 service c2-example-com -n istio-private-gateways
$ kubectl delete --context=$CTX_CLUSTER1 endpoints c2-example-com -n istio-private-gateways
$ kubectl apply --context=$CTX_CLUSTER1 -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

### Delete exposure of services in `cluster2`

{{< text bash >}}
$ kubectl delete --context=$CTX_CLUSTER2 virtualservice privately-exposed-services -n istio-private-gateways
$ kubectl delete --context=$CTX_CLUSTER2 gateway istio-private-ingressgateway -n istio-private-gateways
{{< /text >}}

### Delete the private gateway in `cluster1`

1.  Undeploy the private egress gateway from `cluster1`:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER1 -n istio-private-gateways deployment istio-private-egressgateway
    $ kubectl delete --context=$CTX_CLUSTER1 -n istio-private-gateways service istio-private-egressgateway
    $ kubectl delete --context=$CTX_CLUSTER1 -n istio-private-gateways serviceaccount istio-private-egressgateway-service-account
    {{< /text >}}

1.  Delete the secrets from `cluster1`:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER1 -n istio-private-gateways secrets c1-example-com-certs example-com-ca-certs
    {{< /text >}}

1.  Delete the `istio-private-gateways` namespace from `cluster1`:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER1 namespace istio-private-gateways
    {{< /text >}}

### Delete the private gateway in `cluster2`

1.  Undeploy the private ingress gateway from `cluster2`:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER2 -n istio-private-gateways deployment istio-private-ingressgateway
    $ kubectl delete --context=$CTX_CLUSTER2 -n istio-private-gateways service istio-private-ingressgateway
    $ kubectl delete --context=$CTX_CLUSTER2 -n istio-private-gateways serviceaccount istio-private-ingressgateway-service-account
    {{< /text >}}

1.  Delete the secrets from `cluster2`:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER2 -n istio-private-gateways secrets c2-example-com-certs example-com-ca-certs
    {{< /text >}}

1.  Delete the `istio-private-gateways` namespace from `cluster2`:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER2 namespace istio-private-gateways
    {{< /text >}}

### Disable Istio RBAC in `cluster2`

1.  Disable [Istio RBAC](/docs/concepts/security/#authorization) on the `bookinfo` and `istio-private-gateways`
    namespaces.

    {{< warning >}}
    If you have Istio RBAC enabled on some of your namespaces, remove `bookinfo` and `istio-private-gateways`
    from the list of the included namespaces. The command below assumes that you do not have Istio RBAC in your cluster enabled on namespaces other than `bookinfo` and `istio-private-gateways`.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER2 -n istio-system clusterrbacconfig default
    {{< /text >}}

1.  Delete the service roles and service role bindings:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER2 -n bookinfo servicerolebinding ratings-reader reviews-reader
    $ kubectl delete --context=$CTX_CLUSTER2 -n bookinfo servicerole ratings-reader reviews-reader
    {{< /text >}}

### Delete the Bookinfo services

#### `Cluster1`

1.  Delete the Bookinfo application in `cluster1`:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER1 -f samples/bookinfo/networking/virtual-service-all-v1.yaml
    $ kubectl delete --context=$CTX_CLUSTER1 -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
    $ kubectl delete --context=$CTX_CLUSTER1 -f samples/bookinfo/networking/bookinfo-gateway.yaml
    $ kubectl delete --context=$CTX_CLUSTER1 -f samples/bookinfo/platform/kube/bookinfo.yaml
    {{< /text >}}

#### `Cluster2`

1.  Delete the services in `cluster2`:

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

1.  Delete the `bookinfo` namespace in `cluster2`:

    {{< text bash >}}
    $ kubectl delete namespace bookinfo --context=$CTX_CLUSTER2
    {{< /text >}}

### Delete the sleep samples

{{< text bash >}}
$ kubectl delete -f samples/sleep/sleep.yaml --context=$CTX_CLUSTER1
$ kubectl delete -f samples/sleep/sleep.yaml --context=$CTX_CLUSTER2
{{< /text >}}

## Summary

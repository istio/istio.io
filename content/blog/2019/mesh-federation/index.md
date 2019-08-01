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
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items..metadata.name}' --context=$CTX_CLUSTER2) -c sleep --context=$CTX_CLUSTER2 -- curl myreviews.bookinfo:9080/reviews/0
    {"id": "0","reviews": [{  "reviewer": "Reviewer1",  "text": "An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!", "rating": {"stars": 5, "color": "red"}},{  "reviewer": "Reviewer2",  "text": "Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.", "rating": {"stars": 4, "color": "red"}}]}
    {{< /text >}}

## Deploy private gateways for cross-cluster communication

### Generate certificates and keys for cluster1 and cluster2

{{< text bash >}}
$ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
$ openssl req -subj '/O=example Inc., department 1/CN=c1.example.com' -out c1.example.com.csr -newkey rsa:2048 -nodes -keyout c1.example.com.key
$ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in c1.example.com.csr -out c1.example.com.crt
$ openssl req -subj '/O=example Inc., department 2/CN=c2.example.com' -out c2.example.com.csr -newkey rsa:2048 -nodes -keyout c2.example.com.key
$ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in c2.example.com.csr -out c2.example.com.crt
{{< /text >}}

### Deploy private egress gateway in cluster1

1.  Create `istio-private-gateways`:

    {{< text bash >}}
    $ kubectl create namespace istio-private-gateways --context=$CTX_CLUSTER1
    {{< /text >}}

1. Create Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the client's and CA
   certificates.

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER1 -n istio-private-gateways secret tls c1-example-com-certs --key c1.example.com.key --cert c1.example.com.crt
    $ kubectl create --context=$CTX_CLUSTER1 -n istio-private-gateways secret generic example-com-ca-certs --from-file=example.com.crt
    {{< /text >}}

1.  Deploy a private ingress gateway with a volume to be mounted from the new secrets:

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

1.  Verify that the key and the certificate are successfully loaded in the egress gateway's pod:

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

### Deploy private ingress gateway in cluster2

1.  Create `istio-private-gateways`:

    {{< text bash >}}
    $ kubectl create namespace istio-private-gateways --context=$CTX_CLUSTER2
    {{< /text >}}

1. Create Kubernetes [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) to hold the client's and CA
   certificates.

    {{< text bash >}}
    $ kubectl create --context=$CTX_CLUSTER2 -n istio-private-gateways secret tls c2-example-com-certs --key c2.example.com.key --cert c2.example.com.crt
    $ kubectl create --context=$CTX_CLUSTER2 -n istio-private-gateways secret generic example-com-ca-certs --from-file=example.com.crt
    {{< /text >}}

1.  Deploy a private ingress gateway with a volume to be mounted from the new secrets:

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

## Expose and consume services

### Expose reviews v2

1.  Define a `Gateway`:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER2 -n istio-private-gateways -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: private-ingressgateway
    spec:
      selector:
        istio: private-ingressgateway # use istio default ingress gateway
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
      name: reviews-bookinfo-v2
    spec:
      hosts:
      - c2.example.com
      gateways:
      - private-ingressgateway
      http:
      - match:
        - uri:
            prefix: /bookinfo/myreviews/v2/
        rewrite:
          uri: /
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

1.  Test your configuration by accessing the `myreviews` service in `cluster1`:

    {{< text bash >}}
    $ curl -HHost:c2.example.com --resolve c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT:$CLUSTER2_INGRESS_HOST --cacert example.com.crt --key c1.example.com.key --cert c1.example.com.crt https://c2.example.com:$CLUSTER2_SECURE_INGRESS_PORT/bookinfo/myreviews/v2/reviews/0
    {"id": "0","reviews": [{  "reviewer": "Reviewer1",  "text": "An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!", "rating": {"stars": 5, "color": "black"}},{  "reviewer": "Reviewer2",  "text": "Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.", "rating": {"stars": 4, "color": "black"}}]}
    {{< /text >}}

### Consume reviews v2

Bind reviews exposed from `cluster2` as `reviews.default.svc.cluster.local` in `cluster1`.

1.  Create a Kubernetes service for `c2.example.com` since it is not a real URL. In the real life, you
    would use the real host name of your cluster.

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

1.  Create an egress `Gateway` for `reviews.default.svc.cluster.local`, port 80, and a destination rule for
    traffic directed to the egress gateway.

    Choose the instructions corresponding to whether or not you have
    [mutual TLS Authentication](/docs/tasks/security/mutual-tls/) enabled in Istio.

    {{< tabset cookie-name="mtls" >}}

    {{< tab name="mutual TLS enabled" cookie-value="enabled" >}}

    {{< text_hack bash >}}
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
      name: private-egressgateway
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
    {{< /text_hack >}}

    {{< /tab >}}

    {{< tab name="mutual TLS disabled" cookie-value="disabled" >}}

    {{< text_hack bash >}}
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
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-reviews-default
    spec:
      host: istio-private-egressgateway.istio-private-gateways.svc.cluster.local
      subsets:
      - name: reviews-default
    EOF
    {{< /text_hack >}}

    {{< /tab >}}

    {{< /tabset >}}

1.  Define a `VirtualService` to direct traffic from the sidecars to the egress gateway and from the egress gateway
    to the external service:

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: reviews
    spec:
      hosts:
      - reviews.default.svc.cluster.local
      gateways:
      - mesh
      - istio-private-egressgateway.istio-private-gateways
      http:
      - match:
        - port: 9080
          gateways:
          - mesh
        route:
        - destination:
            host: istio-private-egressgateway.istio-private-gateways.svc.cluster.local
            subset: reviews-default
            port:
              number: 443
          weight: 100
      - match:
          - port: 443
            prefix: /
            gateways:
            - istio-private-egressgateway.istio-private-gateways
        route:
        - destination:
            host: c2-example-com.istio-private-gateways.svc.cluster.local
            rewrite:
              uri: /bookinfo/myreviews/v2/
              authority: c2.example.com
            port:
              number: 15433
          weight: 100
    EOF
    {{< /text >}}

### Expose details

### Consume details

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

## Cleanup

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

1.  Delete the gateway and the virtual service in `cluster2`:

    {{< text bash >}}
    $ kubectl delete --context=$CTX_CLUSTER2 -n istio-private-gateways virtualservice reviews-bookinfo-v2
    $ kubectl delete --context=$CTX_CLUSTER2 -n istio-private-gateways gateway private-ingressgateway
    {{< /text >}}

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

## Summary

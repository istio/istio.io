---
title: Version routing in a multicluster service mesh
description: Configuring Istio route rules in a multicluster service mesh.
publishdate: 2019-01-25
subtitle:
attribution: Frank Budinsky
weight: 88
keywords: [traffic-management,multicluster]
---

This article shows how to configure Istio route rules to call remote services in a multicluster service mesh
with a [multiple control plane topology](/docs/concepts/multicluster-deployments/#multiple-control-plane-topology).
We'll run the [Bookinfo sample]({{<github_tree>}}/samples/bookinfo) with version v1 of the `reviews` service
running in one cluster, versions v2 and v3 running in a second cluster.

## Setup clusters

* Set up a multicluster environment with two Istio clusters by following the
    [multiple control planes with gateways](/docs/setup/kubernetes/multicluster-install/gateways/) instructions.

* The `kubectl` command is used to access both clusters with the `--context` flag.
    Use the following command to list your contexts:

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME       CLUSTER    AUTHINFO       NAMESPACE
    *         cluster1   cluster1   user@foo.com   default
              cluster2   cluster2   user@foo.com   default
    {{< /text >}}

* Export the following environment variables with the context names of your configuration:

    {{< text bash >}}
    $ export CTX_CLUSTER1=<cluster1 context name>
    $ export CTX_CLUSTER2=<cluster2 context name>
    {{< /text >}}

## Deploy the bookinfo services in cluster1

Run the `productpage` and `details` services and version v1 of the `reviews` service in `cluster1`:

{{< text bash >}}
$ kubectl label --context=$CTX_CLUSTER1 namespace default istio-injection=enabled
$ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: productpage
  labels:
    app: productpage
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: productpage
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: productpage-v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: productpage
        version: v1
    spec:
      containers:
      - name: productpage
        image: istio/examples-bookinfo-productpage-v1:1.10.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
apiVersion: v1
kind: Service
metadata:
  name: details
  labels:
    app: details
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: details
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: details-v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: details
        version: v1
    spec:
      containers:
      - name: details
        image: istio/examples-bookinfo-details-v1:1.10.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
apiVersion: v1
kind: Service
metadata:
  name: reviews
  labels:
    app: reviews
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: reviews
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: reviews-v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: reviews
        version: v1
    spec:
      containers:
      - name: reviews
        image: istio/examples-bookinfo-reviews-v1:1.10.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
EOF
{{< /text >}}

## Deploy the bookinfo services in cluster2

Run the `ratings` service and version v2 and v3 of the `reviews` service in `cluster2`:

{{< text bash >}}
$ kubectl label --context=$CTX_CLUSTER2 namespace default istio-injection=enabled
$ kubectl apply --context=$CTX_CLUSTER2 -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ratings
  labels:
    app: ratings
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: ratings
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: ratings-v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: ratings
        version: v1
    spec:
      containers:
      - name: ratings
        image: istio/examples-bookinfo-ratings-v1:1.10.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
apiVersion: v1
kind: Service
metadata:
  name: reviews
  labels:
    app: reviews
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: reviews
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: reviews-v2
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: reviews
        version: v2
    spec:
      containers:
      - name: reviews
        image: istio/examples-bookinfo-reviews-v2:1.10.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: reviews-v3
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: reviews
        version: v3
    spec:
      containers:
      - name: reviews
        image: istio/examples-bookinfo-reviews-v3:1.10.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
EOF
{{< /text >}}

## Access the bookinfo application

Create the bookinfo gateway in `cluster1`:

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER1 -f samples/bookinfo/networking/bookinfo-gateway.yaml
{{< /text >}}

Follow the [Bookinfo sample instructions](/docs/examples/bookinfo/#determining-the-ingress-ip-and-port)
to determine the ingress IP and port and then point your browser to `http://$GATEWAY_URL/productpage`.
You should see the productpage with reviews, but without ratings, because only v1 of the `reviews` service
is running on `cluster1` and we have not yet configured access to `cluster2`.

## Create a service entry and destination rule on cluster1 for the remote reviews service

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: reviews-default
spec:
  hosts:
  - reviews.default.global
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 9080
    protocol: http
  resolution: DNS
  addresses:
  - 127.255.0.3
  endpoints:
  - address: ${CLUSTER2_GW_ADDR}
    labels:
      version: v2
      version: v3
    ports:
      http1: 15443 # Do not change this port value
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews-global
spec:
  host: reviews.default.global
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
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

## Create a destination rule on both clusters of the local reviews service

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
aapiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews.default.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
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

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER2 -f - <<EOF
aapiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews.default.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
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

## Create a virtual service to route reviews service traffic

Apply the following virtual service to direct traffic for user `jason` to `reviews` versions v2 and v3 (50/50)
which are running on `cluster2`. Traffic for any other user will go to `reviews` version v1.

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews.default.svc.cluster.local
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: reviews.default.global
        subset: v2
      weight: 50
    - destination:
        host: reviews.default.global
        subset: v3
      weight: 50
  - route:
    - destination:
        host: reviews.default.svc.cluster.local
        subset: v1
EOF
{{< /text >}}

Return to your browser and login as user `jason`. If you refresh the page several times, you should see
the display alternating between black and red ratings stars (v2 and v3). If you logout, you will
only see reviews without ratings (v1).

## Summary

TBD.

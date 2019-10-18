---
title: Authorization for TCP protocol
description: Shows how to set up role-based access control for TCP protocol.
weight: 10
keywords: [security,access-control,rbac,tcp,authorization]
---

This task covers the activities you might need to perform to set up Istio authorization for
TCP protocol in an Istio mesh. You can learn more about the Istio authorization in the
[authorization concept page](/docs/concepts/security/#authorization).

## Before you begin

The activities in this task assume that you:

* Read the [authorization concept](/docs/concepts/security/#authorization).

* Follow the [Kubernetes quick start](/docs/setup/install/kubernetes/) to install Istio.

* Deploy the [Bookinfo](/docs/examples/bookinfo/#deploying-the-application) sample application.

After deploying the Bookinfo application, go to the Bookinfo product page at `http://$GATEWAY_URL/productpage`. On
the product page, you can see the following sections:

* **Book Details** on the lower left side, which includes: book type, number of
  pages, publisher, etc.
* **Book Reviews** on the lower right of the page.

When you refresh the page, the app shows different versions of reviews in the product page.
The app presents the reviews in a round robin style: red stars, black stars, or no stars.

## Installing and configuring a TCP workload

By default, the [Bookinfo](/docs/examples/bookinfo/) example application only includes HTTP protocol.
To show how Istio handles the authorization of TCP protocol, we must update the application to use a
TCP protocol. Follow this procedure to deploy the Bookinfo example app and update its `ratings` workload
to the `v2` version, which talks to a MongoDB backend using TCP.

1. Install `v2` of the `ratings` workload with service account `bookinfo-ratings-v2`:

    * To create the service account and configure the new version of the workload for a cluster
      **with** automatic sidecar injection enabled:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
        {{< /text >}}

    * To create the service account and configure the new version of the workload for a cluster
      **without** automatic sidecar injection enabled:

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@)
        {{< /text >}}

1. Create the appropriate destination rules:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
    {{< /text >}}

    Since the subset referenced in the virtual service rules relies on the destination rules,
    wait a few seconds for the destination rules to propagate before adding the virtual service rules.

1. After the destination rules propagate, update the `reviews` workload to only use the `v2` of the `ratings` workload:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
    {{< /text >}}

1. Go to the Bookinfo product page at (`http://$GATEWAY_URL/productpage`).

    On the product page, you can see an error message on the **Book Reviews** section.
    The message reads: **"Ratings service is currently unavailable."**. The message appears because we
    switched to use the `v2` subset of the `ratings` workload without deploying the MongoDB workload.

1. Deploy the MongoDB workload:

    * To deploy MongoDB in a cluster **with** automatic sidecar injection enabled:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@
        {{< /text >}}

    * To deploy MongoDB in a cluster **without** automatic sidecar injection enabled:

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@)
        {{< /text >}}

1. Go to the Bookinfo product page at `http://$GATEWAY_URL/productpage`.

1. Verify that the **Book Reviews** section shows the reviews.

## Applying a default `deny-all` policy

Run the following command to apply a default `deny-all` policy for the MongoDB workload:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
spec:
  selector:
    matchLabels:
      app: mongodb
EOF
{{< /text >}}

The command creates a `deny-all` policy that selects the MongoDB workload and will deny all requests because
it doesn't have any rules.

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`).  You should see:

* The **Book Details** section on the lower left of the page includes book type, number of pages, publisher, etc.
* The **Book Reviews** section on the lower right of the page includes an error message **"Ratings service is
  currently unavailable"**.

{{< tip >}}
There may be some delays due to caching and other propagation overhead.
{{< /tip >}}

## Enforcing access control on TCP workload

Now let's set up workload-level access control using Istio authorization to allow `v2` of `ratings`
to access the MongoDB workload.

Run the following command to apply the authorization policy:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: bookinfo-ratings-v2
spec:
  selector:
    matchLabels:
      app: mongodb
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/default/sa/bookinfo-ratings-v2"]
    to:
    - operation:
        ports: ["27017"]
EOF
{{< /text >}}

The command creates a `bookinfo-ratings-v2` policy that selects the MongoDB workload and grants the access at port
27017 to the `cluster.local/ns/default/sa/bookinfo-ratings-v2` service account that represents the `ratings-v2` workload.

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). You should see the following sections:

* **Book Details** on the lower left side, which includes: book type, number of pages, publisher, etc.
* **Book Reviews** on the lower right side, which includes: red stars.

{{< tip >}}
There may be some delays due to caching and other propagation overhead.
{{< /tip >}}

## Cleanup

*   Remove Istio authorization policy configuration:

    {{< text bash >}}
    $ kubectl delete authorizationpolicy.security.istio.io/deny-all
    $ kubectl delete authorizationpolicy.security.istio.io/bookinfo-ratings-v2
    {{< /text >}}

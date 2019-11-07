---
title: Authorization for TCP traffic
description: Shows how to set up access control for TCP traffic.
weight: 10
keywords: [security,access-control,rbac,tcp,authorization]
---

This task shows you how to set up Istio authorization for TCP traffic in an Istio mesh.
You can learn more about the Istio authorization in the
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

{{< tip >}}
If you don't see the expected output in the browser as you follow the task, retry in a few seconds
because some delay is possible due to caching and other propagation overhead.
{{< /tip >}}

## Configure access control for a TCP workload

By default, the [Bookinfo](/docs/examples/bookinfo/) example application only uses the HTTP protocol.
To showcase the authorization of TCP traffic, you must update the application to use TCP.
The following steps deploy the Bookinfo application and update its `ratings` workload to the `v2` version,
which talks to a MongoDB backend using TCP, and then apply the authorization policy to the MongoDB workload.

1. Install `v2` of the `ratings` workload with the `bookinfo-ratings-v2` service account:

    {{< tabset cookie-name="sidecar" >}}

    {{< tab name="With automatic sidecar injection" cookie-value="auto" >}}

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="With manual sidecar injection" cookie-value="manual" >}}

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@)
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

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
    now use the `v2` subset of the `ratings` workload but we haven't deployed the MongoDB workload.

1. Deploy the MongoDB workload:

    {{< tabset cookie-name="sidecar" >}}

    {{< tab name="With automatic sidecar injection" cookie-value="auto" >}}

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="With manual sidecar injection" cookie-value="manual" >}}

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@)
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. Go to the Bookinfo product page at `http://$GATEWAY_URL/productpage`.

1. Verify that the **Book Reviews** section shows the reviews.

    With the MongoDB workload deployed and before we configure authorization to only allow authorized requests,
    we need to apply a default `deny-all` policy for the workload to ensure that all requests to the MongoDB
    workload are denied by default.

1. Apply a default `deny-all` policy for the MongoDB workload:

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

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`).  You should see:

    * The **Book Details** section on the lower left of the page includes book type, number of pages, publisher, etc.
    * The **Book Reviews** section on the lower right of the page includes an error message **"Ratings service is
      currently unavailable"**.

    After configuring that all requests be denied by default, we need to create a `bookinfo-ratings-v2`
    policy that lets requests coming from the `cluster.local/ns/default/sa/bookinfo-ratings-v2` service account
    through to the MongoDB workload at port `27017`. We grant access to the service account, because
    requests coming from the `ratings-v2` workload are issued using the `cluster.local/ns/default/sa/bookinfo-ratings-v2`
    service account.

1. Enforce workload-level access control for TCP traffic coming from the
`cluster.local/ns/default/sa/bookinfo-ratings-v2` service account:

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

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`),
    you should see now the following sections working as intended:

    * **Book Details** on the lower left side, which includes: book type, number of pages, publisher, etc.
    * **Book Reviews** on the lower right side, which includes: red stars.

    **Congratulations!** You successfully deployed a workload communicating over TCP traffic and applied
    both a mesh-level and a workload-level authorization policy to enforce access control for the requests.

## Cleanup

1. Remove Istio authorization policy configuration:

    {{< text bash >}}
    $ kubectl delete authorizationpolicy.security.istio.io/deny-all
    $ kubectl delete authorizationpolicy.security.istio.io/bookinfo-ratings-v2
    {{< /text >}}

1. Remove `v2` of the ratings workload and the MongoDB deployment:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
    $ kubectl delete -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@
    {{< /text >}}

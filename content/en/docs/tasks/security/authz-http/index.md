---
title: Authorization for HTTP traffic
description: Shows how to set up role-based access control for HTTP traffic.
weight: 10
keywords: [security,access-control,rbac,authorization]
aliases:
    - /docs/tasks/security/role-based-access-control.html
---

This task shows you how to set up Istio authorization for HTTP traffic in an Istio mesh.
Learn more in our [authorization concept page](/docs/concepts/security/#authorization).

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
If you don't see the expected output in the browser as you follow the task, retry in a few more seconds
because some delay is possible due to caching and other propagation overhead.
{{< /tip >}}

## Configure access control for workloads using HTTP traffic

Using Istio, you can easily setup access control for {{< gloss "workload" >}}workloads{{< /gloss >}}
in your mesh. This task shows you how to set up access control using Istio authorization.
You will start with a simple `deny-all` policy that rejects all requests to the workload,
and then grant more access to the workload gradually and incrementally.

1. Run the following command to create a policy `deny-all`, the policy has no rule so it
   cannot grant permission for any traffic. In other words, it denies all:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: deny-all
      namespace: default
    spec:
      {}
    EOF
    {{< /text >}}

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`).
    You should see `"RBAC: access denied"`. The error shows that the configured `deny-all` policy
    is working as intended, and Istio doesn't have any rules that allow any access to
    workloads in the mesh.

    With Istio, you can easily configure namespace-level access control. You can configure how could workloads
    from a namespace access workloads in another namespace.

1. Run the following command to create a `bookinfo-viewer` policy that allows workloads in the `default`
   and `istio-system` namespaces to access workloads in the `default` namespace with `GET` method:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: "bookinfo-viewer"
      namespace: default
    spec:
      rules:
      - from:
        - source:
            namespaces: ["default", "istio-system"]
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

    Point your browser at Bookinfo's `productpage` (`http://$GATEWAY_URL/productpage`).
    You should see the "Bookinfo Sample" page, with the "Book Details" section in the lower left part
    and the "Book Reviews" section in the lower right part.

1. Remove the policy with the following command before continuing:

    {{< text bash >}}
    $ kubectl delete authorizationpolicy.security.istio.io/bookinfo-viewer
    {{< /text >}}

1. Run the following command to create a `productpage-viewer` policy which allows
   access to the `productpage` workload with `GET` method for all users and workloads:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: "productpage-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: productpage
      rules:
      - to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`).
    Now you should see the "Bookinfo Sample" page. But there are errors `Error fetching product details`
    and `Error fetching product reviews` on the page.

    These errors are expected because we have not granted the `productpage`
    workload access to the `details` and `reviews` workloads. We will fix the
    errors in the following steps.

1. Run the following command to create a policy `details-viewer` to allow the `productpage`
   workload (represented by `principals: ["cluster.local/ns/default/sa/bookinfo-productpage"]`)
   to access the `details` workload through `GET` methods:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: "details-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: details
      rules:
      - from:
        - source:
            principals: ["cluster.local/ns/default/sa/bookinfo-productpage"]
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

1. Run the following command to create a policy `reviews-viewer` to allow the `productpage` workload
   (represented by `principals: ["cluster.local/ns/default/sa/bookinfo-productpage"]`) to access the
   `reviews` workload through `GET` methods:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: "reviews-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: reviews
      rules:
      - from:
        - source:
            principals: ["cluster.local/ns/default/sa/bookinfo-productpage"]
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now you should see the "Bookinfo Sample"
    page with "Book Details" on the lower left part, and "Book Reviews" on the lower right part. However, in the "Book Reviews" section,
    there is an error `Ratings service currently unavailable`.

    This is because "reviews" workload does not have permission to access `ratings` workload.
    To fix this issue, you need to grant the `reviews` workload access to the `ratings` workload.
    We will show how to do that in the next step.

1. Run the following command to create a policy `ratings-viewer` to allow the `reviews` workload
   (represented by `principals: ["cluster.local/ns/default/sa/bookinfo-reviews"]`) to access the
   `ratings` workload through `GET` methods:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: "ratings-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: ratings
      rules:
      - from:
        - source:
            principals: ["cluster.local/ns/default/sa/bookinfo-reviews"]
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`).
    You should see the "black" and "red" ratings in the "Book Reviews" section.

    **Congratulations!** You successfully applied authorization policy to enforce access
    control for workloads using HTTP traffic.

## Clean up

1. Remove all authorization policies from your configuration:

    {{< text bash >}}
    $ kubectl delete authorizationpolicy.security.istio.io/deny-all
    $ kubectl delete authorizationpolicy.security.istio.io/productpage-viewer
    $ kubectl delete authorizationpolicy.security.istio.io/details-viewer
    $ kubectl delete authorizationpolicy.security.istio.io/reviews-viewer
    $ kubectl delete authorizationpolicy.security.istio.io/ratings-viewer
    {{< /text >}}

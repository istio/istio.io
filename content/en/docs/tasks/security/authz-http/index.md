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
If you don't see the expected output in the browser, retry in a few more seconds
as there may be some delays due to caching and other propagation overhead.
{{< /tip >}}

## Enforce mesh-level access control

Using Istio, you can easily setup mesh-level access control for all workloads in your mesh.

Run the following command to create a mesh-level access control policy `deny-all` policy
in the root namespace, A policy in the root namespace will select all workloads in the mesh.

The root namespace is configurable in the [`MeshConfig`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig)
and has the default value of `istio-system`. If you have changed it to a different value from the
default `istio-system`, Please update the value accordingly in the following examples.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
  namespace: istio-system
spec:
  {}
EOF
{{< /text >}}

The `{}` in the policy means `deny-all`, you can also set other mesh-level policy for your own needs.

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`).
Now you should see `"RBAC: access denied"`. The error shows that the configured `deny-all`
policy is working as intended, and Istio doesn't have any rules that allow any access to
workloads in the mesh.

### Clean up mesh-level access control

Disable the configured access control with the following command before continuing:

{{< text bash >}}
$ kubectl delete authorizationpolicy.security.istio.io/deny-all -n istio-system
{{< /text >}}

## Enforce namespace-level access control

With Istio, you can easily setup namespace-level access control. You can configure
how could workloads from a namespace access workloads in another namespace.

The Bookinfo sample deploys the `productpage`, `reviews`, `details`, `ratings` {{< gloss "workload" >}}workloads{{< /gloss >}}
in the `default` namespace. Istio deploys its components, for example `istio-ingressgateway`,
in the `istio-system` namespace.

The following command creates a `bookinfo-viewer` policy that allows workloads in the `default`
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

You can expect to see output similar to the following:

{{< text plain >}}
authorizationpolicy.security.istio.io/bookinfo-viewer created
{{< /text >}}

Now if you point your browser at Bookinfo's `productpage` (`http://$GATEWAY_URL/productpage`).
You should see the "Bookinfo Sample" page, with the "Book Details" section in the lower left part
and the "Book Reviews" section in the lower right part.

### Clean up namespace-level access control

Disable the configured access control with the following command before continuing:

{{< text bash >}}
$ kubectl delete authorizationpolicy.security.istio.io/bookinfo-viewer
{{< /text >}}

## Enforce workload-level access control

This task shows you how to set up workload-level access control using Istio authorization.
You will start with a simple `deny-all` policy that rejects all requests to the workload, and then
grant the permission gradually and incrementally to allow more access to the workload.

1. Apply a default `deny-all` policy for workloads in the default namespace

    The following command creates a `deny-all` policy with no workload selector, the policy will
    select all workloads in the default namespace. The policy will deny all access and we will
    add more policies to grant the access incrementally in following steps.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: deny-all
    spec:
      {}
    EOF
    {{< /text >}}

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`).
    Now you should see `"RBAC: access denied"`. The error shows that the configured `deny-all` policy
    is working as intended, and Istio doesn't have any rules that allow any access
    to workloads in the default namespace.

1. Allow access to the `productpage` workload

    The following command creates a `productpage-viewer` policy which allows
    access to the `productpage` workload with `GET` method for all users and workloads.

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
    and `Error fetching product reviews` on the page. These errors are expected because
    we have not granted the `productpage` workload access to the `details` and `reviews` workloads.
    We will fix the errors in the following steps.

1. Allow access to the `details` and `reviews` workloads

    The following command has the following effects:

    * Creates a `details-viewer` policy which allows access with `GET` method to the `details` workload for
      service account `cluster.local/ns/default/sa/bookinfo-productpage` (representing the `details` workload).

    * Creates a `reviews-viewer` policy which allows access with `GET` method to the `reviews` workload for
      service account `cluster.local/ns/default/sa/bookinfo-productpage` (representing the `reviews` workload).

    Note that in the [setup step](#before-you-begin), we created the `bookinfo-productpage` service account
    for the `productpage` workload. This `bookinfo-productpage` service account is the authenticated identify
    for the `productpage` workload.

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
    ---
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
    there is an error `Ratings service currently unavailable`. This is because "reviews" workload does not have permission to access
    "ratings" workload. To fix this issue, you need to grant the `reviews` workload access to the `ratings` workload.
    We will show how to do that in the next step.

1. Allow access to the `ratings` workload

    The following command creates a policy to allow the `reviews` workload to access the `ratings` workload. Note that in the
    [setup step](#before-you-begin), we created a `bookinfo-reviews` service account for the `reviews` workload. This
    service account is the authenticated identify for the `reviews` workload.

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

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now you should see
    the "black" and "red" ratings in the "Book Reviews" section.

### Clean up workload-level access control

*   Remove all authorization policies from your configuration:

    {{< text bash >}}
    $ kubectl delete authorizationpolicy.security.istio.io/deny-all
    $ kubectl delete authorizationpolicy.security.istio.io/productpage-viewer
    $ kubectl delete authorizationpolicy.security.istio.io/details-viewer
    $ kubectl delete authorizationpolicy.security.istio.io/reviews-viewer
    $ kubectl delete authorizationpolicy.security.istio.io/ratings-viewer
    {{< /text >}}

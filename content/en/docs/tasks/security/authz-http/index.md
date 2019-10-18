---
title: Authorization for HTTP protocol
description: Shows how to set up role-based access control for HTTP protocol.
weight: 10
keywords: [security,access-control,rbac,authorization]
aliases:
    - /docs/tasks/security/role-based-access-control.html
---

This task covers the activities you might need to perform to set up Istio authorization for
HTTP protocol in an Istio mesh. You can read more in [authorization](/docs/concepts/security/#authorization)
and get started with a basic tutorial in Istio Security Basics.

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

## Enforcing Mesh-level access control

Using Istio authorization, you can easily setup mesh-level access control for all workloads in the mesh.

Run the following command to create a mesh-level access control policy:

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

The command creates a `deny-all` policy with no workload selector in the root namespace `istio-system`, the policy
will select all workloads in the mesh.

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now you should see `"RBAC: access denied"`.
This is because Istio authorization is "deny by default" and the `deny-all` policy doesn't have any rules to allow any access to
workloads in the default namespace.

{{< tip >}}
There may be some delays due to caching and other propagation overhead.
{{< /tip >}}

### Cleanup Mesh-level access control

Remove the following configuration before you proceed to the next task:

{{< text bash >}}
$ kubectl delete authorizationpolicy.security.istio.io/deny-all -n istio-system
{{< /text >}}

## Enforcing Namespace-level access control

Using Istio authorization, you can easily setup namespace-level access control by specifying all (or a collection of) workloads
in a namespace are accessible by workloads from another namespace.

In our Bookinfo sample, the `productpage`, `reviews`, `details`, `ratings` workloads are deployed in the `default` namespace.
The Istio components like `istio-ingressgateway` workloads are deployed in the `istio-system` namespace.

We can define a policy that any workload in the `default` namespace is accessible by workloads in the same namespace (i.e., `default`)
and workloads in the `istio-system` namespace.

Run the following command to create a namespace-level access control policy:

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

The command creates a `bookinfo-viewer` policy which allows read access to any workloads in the `default` namespace.

You can expect to see output similar to the following:

{{< text plain >}}
authorizationpolicy.security.istio.io/bookinfo-viewer created
{{< /text >}}

Now if you point your browser at Bookinfo's `productpage` (`http://$GATEWAY_URL/productpage`). You should see the "Bookinfo Sample" page,
with the "Book Details" section in the lower left part and the "Book Reviews" section in the lower right part.

{{< tip >}}
There may be some delays due to caching and other propagation overhead.
{{< /tip >}}

### Cleanup Namespace-level access control

Remove the following configuration before you proceed to the next task:

{{< text bash >}}
$ kubectl delete authorizationpolicy.security.istio.io/bookinfo-viewer
{{< /text >}}

## Enforcing Workload-level access control

This task shows you how to set up workload-level access control using Istio authorization.

### Step 1. applying a default `deny-all` policy

In this step, we will create a default policy that denies all requests to workload in the default namespace.

Run the following command:

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

The command creates a `deny-all` policy with no workload selector, the policy will select all workloads in the default namespace.

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now you should see `"RBAC: access denied"`.
This is because Istio authorization is "deny by default" and the `deny-all` policy doesn't have any rules to allow any access to
workloads in the default namespace.

{{< tip >}}
There may be some delays due to caching and other propagation overhead.
{{< /tip >}}

### Step 2. allowing access to the `productpage` workload

We will create a policy that allows external requests to access the `productpage` workload.

Run the following command:

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

The command creates a `productpage-viewer` policy which allows read access to the `productpage` workload for all users and workloads.

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now you should see the "Bookinfo Sample"
page. But there are errors `Error fetching product details` and `Error fetching product reviews` on the page. These errors
are expected because we have not granted the `productpage` workload access to the `details` and `reviews` workloads. We will fix the errors
in the following steps.

{{< tip >}}
There may be some delays due to caching and other propagation overhead.
{{< /tip >}}

### Step 3. allowing access to the `details` and `reviews` workloads

We will create a policy to allow the `productpage` workload to access the `details` and `reviews` workloads. Note that in the
[setup step](#before-you-begin), we created the `bookinfo-productpage` service account for the `productpage` service. This
`bookinfo-productpage` service account is the authenticated identify for the `productpage` service.

Run the following command:

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

The command has the following effects:

*   Creates a `details-viewer` policy which allows access to the `details` workload for
    `cluster.local/ns/default/sa/bookinfo-productpage` workload account (representing the `details` workload).

*   Creates a `reviews-viewer` policy which allows access to the `reviews` workload for
    `cluster.local/ns/default/sa/bookinfo-productpage` workload account (representing the `reviews` workload).

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now you should see the "Bookinfo Sample"
page with "Book Details" on the lower left part, and "Book Reviews" on the lower right part. However, in the "Book Reviews" section,
there is an error `Ratings service currently unavailable`. This is because "reviews" workload does not have permission to access
"ratings" workload. To fix this issue, you need to grant the `reviews` workload access to the `ratings` workload.
We will show how to do that in the next step.

{{< tip >}}
There may be some delays due to caching and other propagation overhead.
{{< /tip >}}

### Step 4. allowing access to the `ratings` workload

We will create a policy to allow the `reviews` workload to access the `ratings` workload. Note that in the
[setup step](#before-you-begin), we created a `bookinfo-reviews` service account for the `reviews` workload. This
service account is the authenticated identify for the `reviews` workload.

Run the following command to create a policy that allows the `reviews` workload to access the `ratings` workload.

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

The command creates a `ratings-viewer` policy which allows access to the `ratings` workload for
`cluster.local/ns/default/sa/bookinfo-reviews` service account, which represents the `reviews` workload.

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now you should see
the "black" and "red" ratings in the "Book Reviews" section.

{{< tip >}}
There may be some delays due to caching and other propagation overhead.
{{< /tip >}}

### Cleanup Workload-level access control

*   Remove Istio authorization policy configurations:

    {{< text bash >}}
    $ kubectl delete authorizationpolicy.security.istio.io/deny-all
    $ kubectl delete authorizationpolicy.security.istio.io/productpage-viewer
    $ kubectl delete authorizationpolicy.security.istio.io/details-viewer
    $ kubectl delete authorizationpolicy.security.istio.io/reviews-viewer
    $ kubectl delete authorizationpolicy.security.istio.io/ratings-viewer
    {{< /text >}}

---
title: Authorization
description: Shows how to set up role-based access control for services in Istio mesh.
weight: 40
keywords: [security,access-control,rbac,authorization]
---

This task covers the activities you might need to perform to set up Istio authorization, also known
as Istio Role Based Access Control (RBAC), for services in an Istio mesh. You can read more in
[authorization](/docs/concepts/security/#authorization) and get started with
a basic tutorial in Istio Security Basics.

## Before you begin

The activities in this task assume that you:

* Understand [authorization](/docs/concepts/security/#authorization) concepts.

* Have set up Istio on Kubernetes **with authentication enabled** by following the instructions in the
  [quick start](/docs/setup/kubernetes/quick-start/), this tutorial requires mutual TLS to work. Mutual TLS
  authentication should be enabled in the [installation steps](/docs/setup/kubernetes/quick-start/#installation-steps).

* Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

* In this task, we will enable access control based on Service Accounts, which are cryptographically authenticated in the mesh.
In order to give different microservices different access privileges, we will create some service accounts and redeploy Bookinfo
microservices running under them.

    Run the following command to
    * Create service account `bookinfo-productpage`, and redeploy the service `productpage` with the service account.
    * Create service account `bookinfo-reviews`, and redeploy the services `reviews` (deployments `reviews-v2` and `reviews-v3`)
    with the service account.

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-add-serviceaccount.yaml@)
    {{< /text >}}

> If you are using a namespace other than `default`, use `kubectl -n namespace ...` to specify the namespace.

* There is a major update to RBAC in Istio 1.0. Please make sure to remove any existing RBAC config before continuing.

    * Run the following commands to disable the old RBAC functionality, these are no longer needed in Istio 1.0:

    {{< text bash >}}
    $ kubectl delete authorization requestcontext -n istio-system
    $ kubectl delete rbac handler -n istio-system
    $ kubectl delete rule rbaccheck -n istio-system
    {{< /text >}}

    * Run the following commands to remove any existing RBAC policies:

      > You could keep existing policies but you will need to make some changes to the `constraints` and `properties` field
in the policy, see [constraints and properties](/docs/reference/config/authorization/constraints-and-properties/)
for the list of supported keys in `constraints` and `properties`.

    {{< text bash >}}
    $ kubectl delete servicerole --all
    $ kubectl delete servicerolebinding --all
    {{< /text >}}

* Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). You should see:

    * "Book Details" section in the lower left part of the page, including type, pages, publisher, etc.
    * "Book Reviews" section in the lower right part of the page.

    If you refresh the page several times, you should see different versions of reviews shown in productpage,
    presented in a round robin style (red stars, black stars, no stars)

## Enabling Istio authorization

Run the following command to enable Istio authorization for "default" namespace:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/rbac-config-ON.yaml@
{{< /text >}}

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now you should see
`"RBAC: access denied"`. This is because Istio authorization is "deny by default", which means that you need to
explicitly define access control policy to grant access to any service.

> There may be some delays due to caching and other propagation overhead.

## Namespace-level access control

Using Istio authorization, you can easily setup namespace-level access control by specifying all (or a collection of) services
in a namespace are accessible by services from another namespace.

In our Bookinfo sample, the "productpage", "reviews", "details", "ratings" services are deployed in "default" namespace.
The Istio components like "istio-ingressgateway" service are deployed in "istio-system" namespace. We can define a policy that
any service in "default" namespace that has "app" label set to one of the values in ["productpage", "details", "reviews", "ratings"]
is accessible by services in the same namespace (i.e., "default" namespace) and services in "istio-system" namespace.

Run the following command to create a namespace-level access control policy:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/namespace-policy.yaml@
{{< /text >}}

The policy does the following:

*   Creates a `ServiceRole` "service-viewer" which allows read access to any service in "default" namespace that has "app" label
set to one of the values in ["productpage", "details", "reviews", "ratings"]. Note that there is a "constraint" specifying that
the services must have one of the listed "app" labels.

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: service-viewer
      namespace: default
    spec:
      rules:
      - services: ["*"]
        methods: ["GET"]
        constraints:
        - key: "destination.labels[app]"
          values: ["productpage", "details", "reviews", "ratings"]
    {{< /text >}}

*   Creates a `ServiceRoleBinding` that assign the "service-viewer" role to all services in "istio-system" and "default" namespaces.

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-service-viewer
      namespace: default
    spec:
      subjects:
      - properties:
          source.namespace: "istio-system"
      - properties:
          source.namespace: "default"
      roleRef:
        kind: ServiceRole
        name: "service-viewer"
    {{< /text >}}

You can expect to see output similar to the following:

{{< text plain >}}
servicerole "service-viewer" created
servicerolebinding "bind-service-viewer" created
{{< /text >}}

Now if you point your browser at Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). You should see "Bookinfo Sample" page,
with "Book Details" section in the lower left part and "Book Reviews" section in the lower right part.

> There may be some delays due to caching and other propagation overhead.

### Cleanup namespace-level access control

Remove the following configuration before you proceed to the next task:

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/platform/kube/rbac/namespace-policy.yaml@
{{< /text >}}

## Service-level access control

This task shows you how to set up service-level access control using Istio authorization. Before you start, please make sure that:

* You have [enabled Istio authorization](#enabling-istio-authorization).
* You have [removed namespace-level authorization policy](#cleanup-namespace-level-access-control).

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). You should see `"RBAC: access denied"`.
We will incrementally add access permission to the services in Bookinfo sample.

### Step 1. allowing access to "productpage" service

In this step, we will create a policy that allows external requests to view `productpage` service via Ingress.

Run the following command:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
{{< /text >}}

The policy does the following:

*   Creates a `ServiceRole` "productpage-viewer" which allows read access to "productpage" service.

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: productpage-viewer
      namespace: default
    spec:
      rules:
      - services: ["productpage.default.svc.cluster.local"]
        methods: ["GET"]
    {{< /text >}}

*   Creates a `ServiceRoleBinding` "bind-productpager-viewer" which assigns "productpage-viewer" role to all users/services.

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-productpager-viewer
      namespace: default
    spec:
      subjects:
      - user: "*"
      roleRef:
        kind: ServiceRole
        name: "productpage-viewer"
    {{< /text >}}

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now you should see "Bookinfo Sample"
page. But there are errors `"Error fetching product details"` and `"Error fetching product reviews"` on the page. These errors
are expected because we have not granted "productpage" service to access "details" and "reviews" services. We will fix the errors
in the following steps.

> There may be some delays due to caching and other propagation overhead.

### Step 2. allowing access to "details" and "reviews" services

We will create a policy to allow "productpage" service to read "details" and "reviews" services. Note that in the
[setup step](#before-you-begin), we created a service account "bookinfo-productpage" for "productpage" service. This
"bookinfo-productpage" service account is the authenticated identify for "productpage" service.

Run the following command:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy.yaml@
{{< /text >}}

The policy does the following:

*   Creates a `ServiceRole` "details-reviews-viewer" which allows read access to "details" and "reviews" services.

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: details-reviews-viewer
      namespace: default
    spec:
      rules:
      - services: ["details.default.svc.cluster.local", "reviews.default.svc.cluster.local"]
        methods: ["GET"]
    {{< /text >}}

*   Creates a `ServiceRoleBinding` "bind-details-reviews" which assigns "details-reviews-viewer" role to service
account "cluster.local/ns/default/sa/bookinfo-productpage" (representing the "productpage" service).

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-details-reviews
      namespace: default
    spec:
      subjects:
      - user: "spiffe://cluster.local/ns/default/sa/bookinfo-productpage"
      roleRef:
        kind: ServiceRole
        name: "details-reviews-viewer"
    {{< /text >}}

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now you should see "Bookinfo Sample"
page with "Book Details" on the lower left part, and "Book Reviews" on the lower right part. However, in "Book Reviews" section,
there is an error `"Ratings service currently unavailable"`. This is because "reviews" service does not have permission to access
"ratings" service. To fix this issue, you need to grant "reviews" service read access to "ratings" service.
We will show how to do that in the next step.

> There may be some delays due to caching and other propagation overhead.

### Step 3. allowing access to "ratings" service

We will create a policy to allow "reviews" service to read "ratings" service. Note that in the
[setup step](#before-you-begin), we created a service account "bookinfo-reviews" for "reviews" service. This
"bookinfo-reviews" service account is the authenticated identify for "reviews" service.

Run the following command to create a policy that allows "reviews" service to read "ratings" service.

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/ratings-policy.yaml@
{{< /text >}}

The policy does the following:

*   Creates a `ServiceRole` "ratings-viewer" which allows read access to "ratings" service.

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: ratings-viewer
      namespace: default
    spec:
      rules:
      - services: ["ratings.default.svc.cluster.local"]
        methods: ["GET"]
    {{< /text >}}

*   Creates a `ServiceRoleBinding` "bind-ratings" which assigns "ratings-viewer" role to service
account "cluster.local/ns/default/sa/bookinfo-reviews", which represents the "reviews" services.

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-ratings
      namespace: default
    spec:
      subjects:
      - user: "spiffe://cluster.local/ns/default/sa/bookinfo-reviews"
      roleRef:
        kind: ServiceRole
        name: "ratings-viewer"
    {{< /text >}}

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now you should see
the "black" and "red" ratings in "Book Reviews" section.

> There may be some delays due to caching and other propagation overhead.

## Cleanup

*   Remove Istio authorization policy configuration:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/ratings-policy.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
    {{< /text >}}

    Alternatively, you can delete all `ServiceRole` and `ServiceRoleBinding` resources by running the following commands:

    {{< text bash >}}
    $ kubectl delete servicerole --all
    $ kubectl delete servicerolebinding --all
    {{< /text >}}

*   Disable Istio authorization:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-config-ON.yaml@
    {{< /text >}}

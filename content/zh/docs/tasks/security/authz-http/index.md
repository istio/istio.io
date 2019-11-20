---
title: Authorization for HTTP Services
description: Shows how to set up role-based access control for HTTP services.
weight: 10
keywords: [security,access-control,rbac,authorization]
aliases:
    - /zh/docs/tasks/security/role-based-access-control.html
---

This task covers the activities you might need to perform to set up Istio authorization, also known
as Istio Role Based Access Control (RBAC), for HTTP services in an Istio mesh. You can read more in
[authorization](/docs/concepts/security/#authorization) and get started with
a basic tutorial in Istio Security Basics.

## Before you begin

The activities in this task assume that you:

* Read the [authorization concept](/docs/concepts/security/#authorization).

* Follow the [Kubernetes quick start](/docs/setup/getting-started/) to install Istio.

* Deploy the [Bookinfo](/docs/examples/bookinfo/#deploying-the-application) sample application.

After deploying the Bookinfo application, go to the Bookinfo product page at `http://$GATEWAY_URL/productpage`. On
the product page, you can see the following sections:

* **Book Details** on the lower left side, which includes: book type, number of
  pages, publisher, etc.
* **Book Reviews** on the lower right of the page.

When you refresh the page, the app shows different versions of reviews in the product page.
The app presents the reviews in a round robin style: red stars, black stars, or no stars.

## Enabling Istio authorization

Run the following command to enable Istio authorization for the `default` namespace:

{{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="enabling_istio_authorization.sh" >}}

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now you should see
`"RBAC: access denied"`. This is because Istio authorization is "deny by default", which means that you need to
explicitly define access control policy to grant access to any service.

{{< tip >}}
There may be some delays due to caching and other propagation overhead.
{{< /tip >}}

## Enforcing Namespace-level access control

Using Istio authorization, you can easily setup namespace-level access control by specifying all (or a collection of) services
in a namespace are accessible by services from another namespace.

In our Bookinfo sample, the `productpage`, `reviews`, `details`, `ratings` services are deployed in the `default` namespace.
The Istio components like `istio-ingressgateway` service are deployed in the `istio-system` namespace. We can define a policy that
any service in the `default` namespace that has the `app` label set to one of the values of
`productpage`, `details`, `reviews`, or `ratings`
is accessible by services in the same namespace (i.e., `default`) and services in the `istio-system` namespace.

Run the following command to create a namespace-level access control policy:

{{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="enforcing_namespace_level_access_control_apply.sh" >}}

Once applied, the policy has the following effects:

*   Creates a `ServiceRole` `service-viewer` which allows read access to any service in the `default` namespace that has
the `app` label
set to one of the values `productpage`, `details`, `reviews`, or `ratings`. Note that there is a
constraint specifying that
the services must have one of the listed `app` labels.

    {{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="enforcing_namespace_level_access_control_service_viewer.yaml" >}}

*   Creates a `ServiceRoleBinding` that assigns the `service-viewer` role to all services in the `istio-system` and `default` namespaces.

    {{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="enforcing_namespace_level_access_control_bind_service_viewer.yaml" >}}

You can expect to see output similar to the following:

{{< text plain >}}
servicerole "service-viewer" created
servicerolebinding "bind-service-viewer" created
{{< /text >}}

Now if you point your browser at Bookinfo's `productpage` (`http://$GATEWAY_URL/productpage`). You should see the "Bookinfo Sample" page,
with the "Book Details" section in the lower left part and the "Book Reviews" section in the lower right part.

{{< tip >}}
There may be some delays due to caching and other propagation overhead.
{{< /tip >}}

### Cleanup namespace-level access control

Remove the following configuration before you proceed to the next task:

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/platform/kube/rbac/namespace-policy.yaml@
{{< /text >}}

## Enforcing Service-level access control

This task shows you how to set up service-level access control using Istio authorization. Before you start, please make sure that:

* You have [enabled Istio authorization](#enabling-istio-authorization).
* You have [removed namespace-level authorization policy](#cleanup-namespace-level-access-control).

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). You should see `"RBAC: access denied"`.
We will incrementally add access permission to the services in the Bookinfo sample.

### Step 1. allowing access to the `productpage` service

In this step, we will create a policy that allows external requests to access the `productpage` service via Ingress.

Run the following command:

{{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="enforcing_service_level_access_control_step1_apply.sh" >}}

Once applied, the policy has the following effects:

*   Creates a `ServiceRole` `productpage-viewer` which allows read access to the `productpage` service.

    {{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="enforcing_service_level_access_control_step1_productpage_viewer.yaml" >}}

*   Creates a `ServiceRoleBinding` `bind-productpage-viewer` which assigns the `productpage-viewer` role to all
users and services.

    {{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="enforcing_service_level_access_control_step1_bind_productpage_viewer.yaml" >}}

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now you should see the "Bookinfo Sample"
page. But there are errors `Error fetching product details` and `Error fetching product reviews` on the page. These errors
are expected because we have not granted the `productpage` service access to the `details` and `reviews` services. We will fix the errors
in the following steps.

{{< tip >}}
There may be some delays due to caching and other propagation overhead.
{{< /tip >}}

### Step 2. allowing access to the `details` and `reviews` services

We will create a policy to allow the `productpage` service to access the `details` and `reviews` services. Note that in the
[setup step](#before-you-begin), we created the `bookinfo-productpage` service account for the `productpage` service. This
`bookinfo-productpage` service account is the authenticated identify for the `productpage` service.

Run the following command:

{{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="enforcing_service_level_access_control_step2_apply.sh" >}}

Once applied, the policy has the following effects:

*   Creates a `ServiceRole` `details-reviews-viewer` which allows access to the `details` and `reviews` services.

    {{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="enforcing_service_level_access_control_step2_details_reviews_viewer.yaml" >}}

*   Creates a `ServiceRoleBinding` `bind-details-reviews` which assigns the `details-reviews-viewer` role to the
`cluster.local/ns/default/sa/bookinfo-productpage` service account (representing the `productpage` service).

    {{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="enforcing_service_level_access_control_step2_bind_details_reviews.yaml" >}}

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now you should see the "Bookinfo Sample"
page with "Book Details" on the lower left part, and "Book Reviews" on the lower right part. However, in the "Book Reviews" section,
there is an error `Ratings service currently unavailable`. This is because "reviews" service does not have permission to access
"ratings" service. To fix this issue, you need to grant the `reviews` service access to the `ratings` service.
We will show how to do that in the next step.

{{< tip >}}
There may be some delays due to caching and other propagation overhead.
{{< /tip >}}

### Step 3. allowing access to the `ratings` service

We will create a policy to allow the `reviews` service to access the `ratings` service. Note that in the
[setup step](#before-you-begin), we created a `bookinfo-reviews` service account for the `reviews` service. This
service account is the authenticated identify for the `reviews` service.

Run the following command to create a policy that allows the `reviews` service to access the `ratings` service.

{{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="enforcing_service_level_access_control_step3_apply.sh" >}}

Once applied, the policy has the following effects:

*   Creates a `ServiceRole` `ratings-viewer` which allows access to the `ratings` service.

    {{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="enforcing_service_level_access_control_step3_ratings_viewer.yaml" >}}

*   Creates a `ServiceRoleBinding` `bind-ratings` which assigns `ratings-viewer` role to the
`cluster.local/ns/default/sa/bookinfo-reviews` service account, which represents the `reviews` service.

    {{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="enforcing_service_level_access_control_step3_bind_ratings.yaml" >}}

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now you should see
the "black" and "red" ratings in the "Book Reviews" section.

{{< tip >}}
There may be some delays due to caching and other propagation overhead.
{{< /tip >}}

## Cleanup

*   Remove Istio authorization policy configuration:

    {{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="remove_istio_authorization_policy.sh" >}}

    Alternatively, you can delete all `ServiceRole` and `ServiceRoleBinding` resources by running the following commands:

    {{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="remove_istio_authorization_policy_alternative.sh" >}}

*   Disable Istio authorization:

    {{< text_import file="examples/TestAuthorizationForHTTPServices.txt" snippet="disabling_istio_authorization.sh" >}}

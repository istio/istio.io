---
title: Role-Based Access Control
description: Shows how to set up role-based access control for services in Istio mesh.
weight: 40
---

This task shows how to set up role-based access control (RBAC) for services in Istio mesh. You can read more about Istio
RBAC from [Istio RBAC concept page](/docs/concepts/security/rbac/).

## Before you begin

* Set up Istio on auth-enabled Kubernetes by following the instructions in the
  [quick start](/docs/setup/kubernetes/quick-start/).
  Note that authentication should be enabled at step 5 in the
  [installation steps](/docs/setup/kubernetes/quick-start/#installation-steps).

* Deploy the [Bookinfo](/docs/guides/bookinfo/) sample application.

> The current Istio release may not have the up-to-date Istio RBAC samples. So before you continue, you
need to copy these [configuration files](https://github.com/istio/istio/blob/{{<branch_name>}}/samples/bookinfo/kube) to
`samples/bookinfo/kube` directory under where you installed Istio, and replace the original ones. The files include
`bookinfo-add-serviceaccount.yaml`, `istio-rbac-enable.yaml`, `istio-rbac-namespace.yaml`, `istio-rbac-productpage.yaml`,
`istio-rbac-details-reviews.yaml`, `istio-rbac-ratings.yaml`.

*   In this task, we will enable access control based on Service Accounts, which are cryptographically authenticated in the Istio mesh.
In order to give different microservices different access privileges, we will create some service accounts and redeploy Bookinfo
microservices running under them.

    Run the following command to
    * Create service account `bookinfo-productpage`, and redeploy the service `productpage` with the service account.
    * Create service account `bookinfo-reviews`, and redeploy the services `reviews` (deployments `reviews-v2` and `reviews-v3`)
    with the service account.

    ```command
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/kube/bookinfo-add-serviceaccount.yaml@)
    serviceaccount "bookinfo-productpage" created
    deployment "productpage-v1" configured
    serviceaccount "bookinfo-reviews" created
    deployment "reviews-v2" configured
    deployment "reviews-v3" configured
    ```

> If you are using a namespace other than `default`, use `istioctl -n namespace ...` to specify the namespace.

Point your browser at the Bookinfo `productpage` (http://$GATEWAY_URL/productpage). You should see:
* "Book Details" section in the lower left part of the page, including type, pages, publisher, etc.
* "Book Reviews" section in the lower right part of the page.

## Enabling Istio RBAC

Run the following command to enable Istio RBAC for "default" namespace.

> If you are using a namespace other than `default`, edit the file `samples/bookinfo/kube/istio-rbac-enable.yaml`,
and specify the namespace, say `"your-namespace"`, in the `match` statement in `rule` spec
`"match: destination.namespace == "your-namespace"`.

```command
$ istioctl create -f @samples/bookinfo/kube/istio-rbac-enable.yaml@
```

> If you have conflicting rules that you set in previous tasks, use `istioctl replace` instead of `istioctl create`.

It also defines "requestcontext", which is an instance of the
[authorization template](/docs/reference/config/policy-and-telemetry/templates/authorization/).
"requestcontext" defines the input to the RBAC engine at runtime.

Point your browser at the Bookinfo `productpage` (http://$GATEWAY_URL/productpage). Now you should see
`"PERMISSION_DENIED:handler.rbac.istio-system:RBAC: permission denied."` This is because Istio RBAC is "deny by default",
which means that you need to explicitly define access control policy to grant access to any service.

> There may be delay due to caching on browser and Istio proxy.

## Namespace-level access control

Using Istio RBAC, you can easily setup namespace-level access control by specifying all (or a collection of) services
in a namespace are accessible by services from another namespace.

In our Bookinfo sample, the "productpage", "reviews", "details", "ratings" services are deployed in "default" namespace.
The Istio components like "ingress" service are deployed in "istio-system" namespace. We can define a policy that
any service in "default" namespace that has "app" label set to one of the values in ["productpage", "details", "reviews", "ratings"]
is accessible by services in the same namespace (i.e., "default" namespace) and services in "istio-system" namespace.

Run the following command to create a namespace-level access control policy.

```command
$ istioctl create -f @samples/bookinfo/kube/istio-rbac-namespace.yaml@
```

The policy does the following:

*   Creates a `ServiceRole` "service-viewer" which allows read access to any service in "default" namespace that has "app" label
set to one of the values in ["productpage", "details", "reviews", "ratings"]. Note that there is a "constraint" specifying that
the services must have one of the listed "app" labels.

    ```yaml
        apiVersion: "config.istio.io/v1alpha2"
        kind: ServiceRole
        metadata:
          name: service-viewer
          namespace: default
        spec:
          rules:
          - services: ["*"]
            methods: ["GET"]
            constraints:
            - key: "app"
              values: ["productpage", "details", "reviews", "ratings"]
    ```

*   Creates a `ServiceRoleBinding` that assign the "service-viewer" role to all services in "istio-system" and "default" namespaces.

    ```yaml
        apiVersion: "config.istio.io/v1alpha2"
        kind: ServiceRoleBinding
        metadata:
          name: bind-service-viewer
          namespace: default
        spec:
          subjects:
          - properties:
              namespace: "istio-system"
          - properties:
              namespace: "default"
          roleRef:
            kind: ServiceRole
            name: "service-viewer"
    ```

You can expect to see output similar to the following:

```plain
servicerole "service-viewer" created
servicerolebinding "bind-service-viewer" created
```

Now if you point your browser at Bookinfo `productpage` (http://$GATEWAY_URL/productpage). You should see "Bookinfo Sample" page,
with "Book Details" section in the lower left part and "Book Reviews" section in the lower right part.

  > There may be delay due to caching on browser and Istio proxy.

### Cleanup namespace-level access control

Remove the following configuration before you proceed to the next task:

```command
$ istioctl delete -f @samples/bookinfo/kube/istio-rbac-namespace.yaml@
```

## Service-level access control

This task shows you how to set up service-level access control using Istio RBAC. Before you start, please make sure that:
* You have [enabled Istio RBAC](#enabling-istio-rbac).
* You have [removed namespace-level Istio RBAC policy](#cleanup-namespace-level-access-control).

Point your browser at the Bookinfo `productpage` (http://$GATEWAY_URL/productpage). You should see
`"PERMISSION_DENIED:handler.rbac.istio-system:RBAC: permission denied."` We will incrementally add
access to the services in Bookinfo sample.

### Step 1. allowing access to "productpage" service

In this step, we will create a policy that allows external requests to view `productpage` service via Ingress.

Run the following command:

```command
$ istioctl create -f @samples/bookinfo/kube/istio-rbac-productpage.yaml@
```

The policy does the following:

*   Creates a `ServiceRole` "productpage-viewer" which allows read access to "productpage" service.

    ```yaml
        apiVersion: "config.istio.io/v1alpha2"
        kind: ServiceRole
        metadata:
          name: productpage-viewer
          namespace: default
        spec:
          rules:
          - services: ["productpage.default.svc.cluster.local"]
            methods: ["GET"]
    ```

*   Creates a `ServiceRoleBinding` "bind-productpager-viewer" which assigns "productpage-viewer" role to all users/services.

    ```yaml
        apiVersion: "config.istio.io/v1alpha2"
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
    ```

Point your browser at the Bookinfo `productpage` (http://$GATEWAY_URL/productpage). Now you should see "Bookinfo Sample"
page. But there are errors `"Error fetching product details"` and `"Error fetching product reviews"` on the page. These errors
are expected because we have not granted "productpage" service to access "details" and "reviews" services. We will fix the errors
in the following steps.

> There may be delay due to caching on browser and Istio proxy.

### Step 2. allowing "productpage" service to access "details" and "reviews" services

We will create a policy to allow "productpage" service to read "details" and "reviews" services. Note that in the
[setup step](#before-you-begin), we created a service account "bookinfo-productpage" for "productpage" service. This
"bookinfo-productpage" service account is the authenticated identify for "productpage" service.

Run the following command:

```command
$ istioctl create -f @samples/bookinfo/kube/istio-rbac-details-reviews.yaml@
```

The policy does the following:

*   Creates a `ServiceRole` "details-reviews-viewer" which allows read access to "details" and "reviews" services.

    ```yaml
        apiVersion: "config.istio.io/v1alpha2"
        kind: ServiceRole
        metadata:
          name: details-reviews-viewer
          namespace: default
        spec:
          rules:
          - services: ["details.default.svc.cluster.local", "reviews.default.svc.cluster.local"]
            methods: ["GET"]
    ```

*   Creates a `ServiceRoleBinding` "bind-details-reviews" which assigns "details-reviews-viewer" role to service
account "cluster.local/ns/default/sa/bookinfo-productpage" (representing the "productpage" service).

    ```yaml
        apiVersion: "config.istio.io/v1alpha2"
        kind: ServiceRoleBinding
        metadata:
          name: bind-details-reviews
          namespace: default
        spec:
          subjects:
          - user: "cluster.local/ns/default/sa/bookinfo-productpage"
          roleRef:
            kind: ServiceRole
            name: "details-reviews-viewer"
    ```

Point your browser at the Bookinfo `productpage` (http://$GATEWAY_URL/productpage). Now you should see "Bookinfo Sample"
page with "Book Details" on the lower left part, and "Book Reviews" on the lower right part. However, in "Book Reviews" section,
there is an error `"Ratings service currently unavailable"`. This is because "reviews" service does not have permission to access
"ratings" service. To fix this issue, you need to grant "reviews" service read access to "ratings" service.
We will show how to do that in the next step.

> There may be delay due to caching on browser and Istio proxy.

### Step 3. allowing "reviews" service to access "ratings" service

We will create a policy to allow "reviews" service to read "ratings" service. Note that in the
[setup step](#before-you-begin), we created a service account "bookinfo-reviews" for "reviews" service. This
"bookinfo-reviews" service account is the authenticated identify for "reviews" service.

Run the following command to create a policy that allows "reviews" service to read "ratings" service.

```command
$ istioctl create -f @samples/bookinfo/kube/istio-rbac-ratings.yaml@
```

The policy does the following:

*   Creates a `ServiceRole` "ratings-viewer" which allows read access to "ratings" service.

    ```yaml
        apiVersion: "config.istio.io/v1alpha2"
        kind: ServiceRole
        metadata:
          name: ratings-viewer
          namespace: default
        spec:
          rules:
          - services: ["ratings.default.svc.cluster.local"]
            methods: ["GET"]
    ```

*   Creates a `ServiceRoleBinding` "bind-ratings" which assigns "ratings-viewer" role to service
account "cluster.local/ns/default/sa/bookinfo-reviews", which represents the "reviews" services.

    ```yaml
        apiVersion: "config.istio.io/v1alpha2"
        kind: ServiceRoleBinding
        metadata:
          name: bind-ratings
          namespace: default
        spec:
          subjects:
          - user: "cluster.local/ns/default/sa/bookinfo-reviews"
          roleRef:
            kind: ServiceRole
            name: "ratings-viewer"
    ```

Point your browser at the Bookinfo `productpage` (http://$GATEWAY_URL/productpage). Now you should see
the "black" and "red" ratings in "Book Reviews" section.

> There may be delay due to caching on browser and Istio proxy.

If you would like to only see "red" ratings in "Book Reviews" section, you can do that by specifying that only "reviews"
service at version "v3" can access "ratings" service.

```yaml
apiVersion: "config.istio.io/v1alpha2"
kind: ServiceRoleBinding
metadata:
  name: bind-ratings
  namespace: default
spec:
  subjects:
  - user: "cluster.local/ns/default/sa/bookinfo-reviews"
    properties:
      version: "v3"
  roleRef:
    kind: ServiceRole
    name: "ratings-viewer"
```

## Cleanup

*   Remove Istio RBAC policy configuration:

    ```command
    $ istioctl delete -f @samples/bookinfo/kube/istio-rbac-ratings.yaml@
    $ istioctl delete -f @samples/bookinfo/kube/istio-rbac-details-reviews.yaml@
    $ istioctl delete -f @samples/bookinfo/kube/istio-rbac-productpage.yaml@
    ```

    Alternatively, you can delete all `ServiceRole` and `ServiceRoleBinding` resources by running the following commands:

    ```command
    $ kubectl delete servicerole --all
    $ kubectl delete servicerolebinding --all
    ```

*   Disable Istio RBAC:

    ```command
    $ istioctl delete -f @samples/bookinfo/kube/istio-rbac-enable.yaml@
    ```

## What's next

* Learn more about [Istio RBAC](/docs/concepts/security/rbac/).

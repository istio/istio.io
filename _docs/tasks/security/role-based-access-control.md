---
title: Setting up Istio Role-Based Access Control
overview: This task shows how to set up role-based access control for services in Istio mesh.

order: 30

layout: docs
type: markdown
---
{% include home.html %}

This task shows how to set up role-based access control (RBAC) for services in Istio mesh. You can read more about Istio
RBAC from [Istio RBAC concept page](https://istio.io/docs/concepts/security/rbac.html).

## Before you begin

* Set up Istio on auth-enabled Kubernetes by following the instructions in the
  [quick start]({{home}}/docs/setup/kubernetes/quick-start.html).
  Note that authentication should be enabled at step 5 in the
  [installation steps]({{home}}/docs/setup/kubernetes/quick-start.html#installation-steps).

* Deploy the [BookInfo]({{home}}/docs/guides/bookinfo.html) sample application.

 *> Note: Some sample configurations we use below are not in the current Istio release yet. So before you continue, you
 need to copy the following configuration files from https://github.com/istio/istio/tree/master/samples/bookinfo/kube to
 "samples/bookinfo/kube" directory under where you installed Istio. The files include `bookinfo-add-serviceaccount.yaml`
 (replace the original one), `istio-rbac-enable.yaml`, `istio-rbac-namespace.yaml`, `istio-rbac-productpage.yaml`,
 `istio-rbac-details-reviews.yaml`, `istio-rbac-ratings.yaml`.*

* In this task, we will enable access control based on Service Accounts, which are cryptographically authenticated in the Istio mesh.
In order to give different microservices different access privileges, we will create some service accounts and redeploy BookInfo
microservices running under them.

  Run the following command to
  * Create service account `bookinfo-productpage`, and redeploy the service `productpage` with the service account.
  * Create service account `bookinfo-reviews`, and redeploy the services `reviews` (deployments `reviews-v2` and `reviews-v3`)
  with the service account.

  ```bash
  kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/kube/bookinfo-add-serviceaccount.yaml)
  ```

  You can expect to see the output similar to the following:
  ```bash
  serviceaccount "bookinfo-productpage" created
  deployment "productpage-v1" configured
  serviceaccount "bookinfo-reviews" created
  deployment "reviews-v2" configured
  deployment "reviews-v3" configured
  ```


  > Note: if you are using a namespace other than `default`,
    use `istioctl -n namespace ...` to specify the namespace.

Point your browser at the BookInfo `productpage` (http://$GATEWAY_URL/productpage). You should see:
* "Book Details" section in the lower left part of the page, including type, pages, publisher, etc.
* "Book Reviews" section in the lower right part of the page.

## Enabling Istio RBAC

Run the following command to enable Istio RBAC.

  ```bash
  kubectl apply -f samples/bookinfo/kube/istio-rbac-enable.yaml
  ```

It also defines "requestcontext", which is an instance of the
[authorization template](https://github.com/istio/istio/blob/master/mixer/template/authorization/template.proto).
"requestcontext" defines the input to the RBAC engine at runtime.

Point your browser at the BookInfo `productpage` (http://$GATEWAY_URL/productpage). Now you should see
"PERMISSION_DENIED:handler.rbac.istio-system:RBAC: permission denied." This is because Istio RBAC is "deny by default",
which means that you need to explicitly define access control policy to grant access to any service.

  > Note: There may be delay due to caching on browser and Istio proxy.

## Namespace-Level Access Control

Using Istio RBAC, you can easily setup namespace-level access control by specifying all (or a collection of) services
in a namespace are accessible by services from another namespace.

In our BookInfo sample, the "productpage", "reviews", "details", "ratings" services are deployed in "default" namespace.
The Istio components like "ingress" service are deployed in "istio-system" namespace. We can define a policy that all
services in "default" namespace are accessible by services in the same namespace (i.e., "default" namespace) and
services in "istio-system" namespace.

Run the following command to create a namespace-level access control policy.
  ```bash
  kubectl apply -f samples/bookinfo/kube/istio-rbac-namespace.yaml
  ```

The policy does the following:
* Creates a ServiceRole "service-viewer" which allows read access to any services in "default" namespace.
  ```rule
  apiVersion: "config.istio.io/v1alpha2"
  kind: ServiceRole
  metadata:
    name: service-viewer
    namespace: default
  spec:
    rules:
    - services: ["*"]
      methods: ["GET"]
  ```
* Creates a ServiceRoleBinding that assign the "service-viewer" role to all services in "istio-system" and "default" namespaces.
  ```rule
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

You can expect to see the output similar to the following:
```bash
servicerole "service-viewer" created
servicerolebinding "bind-service-viewer" created
```

Now if you point your browser at BookInfo `productpage` (http://$GATEWAY_URL/productpage). You should see "BookInfo Sample" page,
with "Book Details" section in the lower left part and "Book Reviews" section in the lower right part.

  > Note: There may be delay due to caching on browser and Istio proxy.

### Cleanup Namespace-Level Access Control

Remove the following configuration before you proceed to the next task:
```bash
kubectl delete -f samples/bookinfo/kube/istio-rbac-namespace.yaml
```

## Service-Level Access Control

This task shows you how to set up service-level access control using Istio RBAC. Before you start, please make sure that:
* You have [enabled Istio RBAC](#enabling-istio-rbac).
* You have [removed namespace-level Istio RBAC policy](#cleanup-namespace-level-access-control).

Point your browser at the BookInfo `productpage` (http://$GATEWAY_URL/productpage). You should see
"PERMISSION_DENIED:handler.rbac.istio-system:RBAC: permission denied." We will incrementally add
access to the services in BookInfo sample.

### Step 1. Allowing Access to "productpage" Service

In this step, we will create a policy that allows external requests to view `productpage` service via Ingress.

Run the following command:
  ```bash
  kubectl apply -f samples/bookinfo/kube/istio-rbac-productpage.yaml
  ```

The policy does the following:
* Creates a ServiceRole "productpage-viewer" which allows read access to "productpage" service.
  ```rule
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

* Creates a ServiceRoleBinding "bind-productpager-viewer" which assigns "productpage-viewer" role to services from "istio-system" namespace.
  ```rule
  apiVersion: "config.istio.io/v1alpha2"
  kind: ServiceRoleBinding
  metadata:
    name: bind-productpager-viewer
    namespace: default
  spec:
    subjects:
    - properties:
        namespace: "istio-system"
    roleRef:
      kind: ServiceRole
      name: "productpage-viewer"
  ```

Point your browser at the BookInfo `productpage` (http://$GATEWAY_URL/productpage). Now you should see "BookInfo Sample"
page. But there are errors "Error fetching product details" and "Error fetching product reviews" on the page. These errors
are expected because we have not granted "productpage" service to access "details" and "reviews" services. We will fix the errors
in the following steps.

  > Note: There may be delay due to caching on browser and Istio proxy.

### Step 2. Allowing "productpage" Service to Access "details" and "reviews" Services

We will create a policy to allow "productpage" service to read "details" and "reviews" services. Note that in the
[setup step](#before-you-begin), we created a service account "bookinfo-productpage" for "productpage" service. This
"bookinfo-productpage" service account is the authenticated identify for "productpage" service.

Run the following command:
  ```bash
  kubectl apply -f samples/bookinfo/kube/istio-rbac-details-reviews.yaml
  ```

The policy does the following:
* Creates a ServiceRole "details-reviews-viewer" which allows
  * Read access to "details" service, and
  * Read access to "reviews" services at versions "v2" and "v3". Note that there is a "constraint" specifying that "version" must be
  "v2" or "v3".
  ```rule
  apiVersion: "config.istio.io/v1alpha2"
  kind: ServiceRole
  metadata:
    name: details-reviews-viewer
    namespace: default
  spec:
    rules:
    - services: ["details.default.svc.cluster.local"]
      methods: ["GET"]
    - services: ["reviews.default.svc.cluster.local"]
      methods: ["GET"]
      constraints:
      - key: "version"
        values: ["v2", "v3"]
  ```

* Creates a ServiceRoleBinding "bind-details-reviews" which assigns "details-reviews-viewer" role to service
account "cluster.local/ns/default/sa/bookinfo-productpage" (representing the "productpage" service).
  ```rule
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

Point your browser at the BookInfo `productpage` (http://$GATEWAY_URL/productpage). Now you should see "BookInfo Sample"
page with "Book Details" on the lower left part, and "Book Reviews" on the lower right part. However, in "Book Reviews" section,
you see one of the following two errors:
1. "Error featching product reviews". This is because "productpage" service is only allowed to access "reviews" service with versions
"v2" or "v3". The error occurs when "productpage" service is routed to "reviews" service at version "v1".
2. "Book Reviews" section is shown on the lower right part of the page. But there is an error "Ratings service currently unavailable". This
is because "reviews" service does not have permission to access "ratings" service.

  > Note: There may be delay due to caching on browser and Istio proxy.

To fix the first error, you need to remove the "version" constraint, so that the "details-reviews-viewer" role look like the following:
  ```rule
  apiVersion: "config.istio.io/v1alpha2"
  kind: ServiceRole
  metadata:
    name: details-reviews-viewer
    namespace: default
  spec:
    rules:
    - services: ["details.default.svc.cluster.local"]
      methods: ["GET"]
    - services: ["reviews.default.svc.cluster.local"]
      methods: ["GET"]
  ```
Note that in the above ServiceRole specification, the "constraints" part in the role is removed.

To fix the second issue, you need to grant "reviews" service read access to "ratings" service. We will show how to do that in the next step.

### Step 3. Allowing "reviews" Service to Access "ratings" Service

We will create a policy to allow "reviews" service to read "ratings" service. Note that in the
[setup step](#before-you-begin), we created a service account "bookinfo-reviews" for "reviews" service. This
"bookinfo-reviews" service account is the authenticated identify for "reviews" service.

Run the following command to create a policy that allows "reviews" service to read "ratings" service.

  ```bash
  kubectl apply -f samples/bookinfo/kube/istio-rbac-ratings.yaml
  ```

The policy does the following:
* Creates a ServiceRole "ratings-viewer" which allows read access to "ratings" service.
  ```rule
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
* Creates a ServiceRoleBinding "bind-ratings" which assigns "ratings-viewer" role to service
account "cluster.local/ns/default/sa/bookinfo-reviews", which represents the "reviews" services.
  ```rule
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

Point your browser at the BookInfo `productpage` (http://$GATEWAY_URL/productpage). Now you should see
the "black" and "red" ratings in "Book Reviews" section.

  > Note: There may be delay due to caching on browser and Istio proxy.

If you would like to only see "red" ratings in "Book Reviews" section, you can do that by specifying that only "reviews"
service at version "v3" can access "ratings" service.
  ```rule
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
* Remove Istio RBAC policy configuration:
  ```bash
    kubectl delete -f samples/bookinfo/kube/istio-rbac-ratings.yaml
    kubectl delete -f samples/bookinfo/kube/istio-rbac-details-reviews.yaml
    kubectl delete -f samples/bookinfo/kube/istio-rbac-productpage.yaml
  ```
Alternatively, you can delete all ServiceRole and ServiceRoleBinding objects by running the following commands:
  ```bash
    kubectl delete servicerole --all
    kubectl delete servicerolebinding --all
  ```

* Disable Istio RBAC:
  ```bash
    kubectl delete -f samples/bookinfo/kube/istio-rbac-enable.ymal
  ```

## Further reading

* Learn more about [Istio RBAC]({{home}}/docs/concepts/security/rbac.html).
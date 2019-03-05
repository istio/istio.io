---
title: Authorization for TCP Services
description: Shows how to set up role-based access control for TCP services.
weight: 10
keywords: [security,access-control,rbac,tcp,authorization]
---

This task covers the activities you might need to perform to set up Istio authorization, also known
as Istio Role Based Access Control (RBAC), for TCP services in an Istio mesh. You can learn more about
the Istio authorization in the [authorization concept page](/docs/concepts/security/#authorization).

## Before you begin

The activities in this task assume that you:

* Read the [authorization concept](/docs/concepts/security/#authorization).

* Follow the instructions in the [quick start](/docs/setup/kubernetes/install/kubernetes/) to install Istio on
  Kubernetes **with authentication enabled**.

* Enable mutual TLS authentication when running the [installation steps](/docs/setup/kubernetes/install/kubernetes/#installation-steps).

The commands used in this task assume the Bookinfo example application is deployed in the default
namespace. To specify a namespace other than the default namespace, use the `-n` option in the command.

## Installing and configuring a TCP service

By default, the [Bookinfo](/docs/examples/bookinfo/) example application only includes HTTP services.
To show how Istio handles the authorization of TCP services, we must update the application to use a
TCP service. Follow this procedure to deploy the Bookinfo example app and update its `ratings` service
to the `v2` version, which talks to a MongoDB backend using TCP.

### Prerequisites

Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

After deploying the Bookinfo application, go to the Bookinfo product page at `http://$GATEWAY_URL/productpage`. On
the product page, you can see:

* The **Book Details** section on the lower left of the page includes book type, number of
  pages, publisher, etc.
* The **Book Reviews** section on the lower right of the page.

When you refresh the page, the app shows different versions of reviews in the product page.
The app presents the reviews in a round robin style: red stars, black stars, or no stars.

### Installing a service using a service account

1. Install `v2` of the `ratings` service with service account `bookinfo-ratings-v2`:

    Istio cryptographically authenticates service accounts in the mesh. To give different services
    different access privileges, we must create a `v2` version of the `ratings` service using the
    `bookinfo-ratings-v2` service account. Other services use the `default` service account.

    * To create the service account and configure the new version of the service for a cluster
      **with** automatic sidecar injection enabled:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/ratings-v2-add-serviceaccount.yaml@
        {{< /text >}}

    * To create the service account and configure the new version of the service for a cluster
      **without** automatic sidecar injection enabled:

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/rbac/ratings-v2-add-serviceaccount.yaml@)
        {{< /text >}}

### Configure the application to use the new version of the service

The Bookinfo application can use multiple versions of each service. Istio requires you to define
a service subset for each version. You must also define the load balancing policy for each subset.
To define the subsets and their load balancing policies, you must create appropriate destination rules.

1. Create the appropriate destination rules:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
    {{< /text >}}

    Since the subset referenced in the virtual service rules relies on the destination rules,
    wait a few seconds for the destination rules to propagate before adding the virtual service rules.

1. After the destination rules propagate, update the `reviews` service to only use the `v2` of the `ratings` service:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
    {{< /text >}}

1. Go to the Bookinfo product page at (`http://$GATEWAY_URL/productpage`).

    On the product page, you can see an error message on the **Book Reviews** section.
    The message reads: **"Ratings service is currently unavailable."**. The message appears because we
    switched to use the `v2` subset of the `ratings` service without deploying the MongoDB service.

1. Deploy the MongoDB service:

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

## Enabling Istio authorization

Run the following command to enable Istio authorization for the MongoDB service:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/rbac-config-on-mongodb.yaml@
{{< /text >}}

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`).  You should see:

* The **Book Details** section on the lower left of the page includes book type, number of pages, publisher, etc.
* The **Book Reviews** section on the lower right of the page includes an error message **"Ratings service is
  currently unavailable"**.

This is because Istio authorization is "deny by default", which means that you need to explicitly
define access control policies to grant access to the MongoDB service.

{{< tip >}}
There may be some delays due to caching and other propagation overhead.
{{< /tip >}}

## Enforcing Service-level access control

Now let's set up service-level access control using Istio authorization to allow `v2` of `ratings`
to access the MongoDB service.

1. Run the following command to apply the authorization policy:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/mongodb-policy.yaml@
    {{< /text >}}

    The step above does the following:

    * Creates a service role "mongodb-viewer" which allows access to the port 27017 of the MongoDB service.

        {{< text yaml >}}
        apiVersion: "rbac.istio.io/v1alpha1"
        kind: ServiceRole
        metadata:
          name: mongodb-viewer
          namespace: default
        spec:
          rules:
          - services: ["mongodb.default.svc.cluster.local"]
            constraints:
            - key: "destination.port"
              values: ["27017"]
        {{< /text >}}

    * Creates a service role binding `bind-mongodb-viewer` which assigns the "mongodb-viewer" role to "bookinfo-ratings-v2".

        {{< text yaml >}}
        apiVersion: "rbac.istio.io/v1alpha1"
        kind: ServiceRoleBinding
        metadata:
          name: bind-mongodb-viewer
          namespace: default
        spec:
          subjects:
          - user: "cluster.local/ns/default/sa/bookinfo-ratings-v2"
          roleRef:
            kind: ServiceRole
            name: "mongodb-viewer"
        {{< /text >}}

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`).  You should see:

    * The **Book Details** section on the lower left of the page includes book type, number of pages, publisher, etc.
    * The **Book Reviews** section on the lower right of the page includes red stars.

    {{< tip >}}
    There may be some delays due to caching and other propagation overhead.
    {{< /tip >}}

1. To confirm the MongoDB service can only be accessed by service account `bookinfo-ratings-v2`:

    Run the following command to delete the `ratings` deployment with service account `bookinfo-ratings-v2`:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/ratings-v2-add-serviceaccount.yaml@
    {{< /text >}}

    Run the following command to deploy the `ratings` deployment with service account `default`:

    * To deploy in a cluster **with** automatic sidecar injection enabled:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
        {{< /text >}}

    * To deploy in a cluster **without** automatic sidecar injection enabled:

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@)
        {{< /text >}}

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`).  You should see:

    * The **Book Details** section on the lower left of the page includes book type, number of pages, publisher, etc.
    * The **Book Reviews** section on the lower right of the page includes an error message **"Ratings
      service is currently unavailable"**.

    {{< tip >}}
    There may be some delays due to caching and other propagation overhead.
    {{< /tip >}}

## Cleanup

*   Remove Istio authorization policy configuration:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/mongodb-policy.yaml@
    {{< /text >}}

    Alternatively, you can delete all service role and service role binding resources by running the following commands:

    {{< text bash >}}
    $ kubectl delete servicerole --all
    $ kubectl delete servicerolebinding --all
    {{< /text >}}

*   Disable Istio authorization:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-config-on-mongodb.yaml@
    {{< /text >}}

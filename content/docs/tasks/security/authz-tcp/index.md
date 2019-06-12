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

* Follow the [Kubernetes quick start](/docs/setup/kubernetes/install/kubernetes/) to install Istio using the **strict mutual TLS profile**.

* Deploy the [Bookinfo](/docs/examples/bookinfo#deploying-the-application) sample application.

After deploying the Bookinfo application, go to the Bookinfo product page at `http://$GATEWAY_URL/productpage`. On
the product page, you can see the following sections:

* **Book Details** on the lower left side, which includes: book type, number of
  pages, publisher, etc.
* **Book Reviews** on the lower right of the page.

When you refresh the page, the app shows different versions of reviews in the product page.
The app presents the reviews in a round robin style: red stars, black stars, or no stars.

## Installing and configuring a TCP service

By default, the [Bookinfo](/docs/examples/bookinfo/) example application only includes HTTP services.
To show how Istio handles the authorization of TCP services, we must update the application to use a
TCP service. Follow this procedure to deploy the Bookinfo example app and update its `ratings` service
to the `v2` version, which talks to a MongoDB backend using TCP.

1. Install `v2` of the `ratings` service with service account `bookinfo-ratings-v2`:

    * To create the service account and configure the new version of the service for a cluster
      **with** automatic sidecar injection enabled:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
        {{< /text >}}

    * To create the service account and configure the new version of the service for a cluster
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

## Enforcing access control on TCP service

Now let's set up service-level access control using Istio authorization to allow `v2` of `ratings`
to access the MongoDB service.

Run the following command to apply the authorization policy:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/mongodb-policy.yaml@
{{< /text >}}

Once applied, the policy has the following effects:

* Creates the following `mongodb-viewer` service role, which allows access to the MongoDB service on port 27017.

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

* Creates the following `bind-mongodb-viewer` service role binding, which assigns the `mongodb-viewer` role
to the `bookinfo-ratings-v2` service.

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

Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). You should see the following sections:

* **Book Details** on the lower left side, which includes: book type, number of pages, publisher, etc.
* **Book Reviews** on the lower right side, which includes: red stars.

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

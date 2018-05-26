---
title: Secure Access Control
description: Shows how to securely control access to a service using service accounts.
weight: 30
---

This task shows how to securely control access to a service,
using the service accounts provided by Istio authentication.

When Istio mutual TLS authentication is enabled, the server authenticates the client according to its certificate, and obtains the client's
service account from the certificate. The service account is in the `source.user` attribute.
For the format of the service account in Istio, please refer to the
[Istio auth identity](/docs/concepts/security/mutual-tls/#identity).

## Before you begin

* Set up Istio on auth-enabled Kubernetes by following the instructions in the
  [quick start](/docs/setup/kubernetes/quick-start/).
  Note that authentication should be enabled at step 5 in the
  [installation steps](/docs/setup/kubernetes/quick-start/#installation-steps).

* Deploy the [Bookinfo](/docs/guides/bookinfo/) sample application.

*   Run the following command to create service account `bookinfo-productpage`,
    and redeploy the service `productpage` with the service account.

    ```command
    $ kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/kube/bookinfo-add-serviceaccount.yaml)
    serviceaccount "bookinfo-productpage" created
    deployment "productpage-v1" configured
    ```

> If you are using a namespace other than `default`,
use `$ istioctl -n namespace ...` to specify the namespace.

## Access control using _denials_

In the [Bookinfo](/docs/guides/bookinfo/) sample application, the `productpage` service is accessing
both the `reviews` service and the `details` service. We would like the `details` service to deny the requests from
the `productpage` service.

1.  Point your browser at the Bookinfo `productpage` (http://$GATEWAY_URL/productpage).

    You should see the "Book Details" section in the lower left part of the page, including type, pages, publisher, etc.
    The `productpage` service obtains the "Book Details" information from the `details` service.

1.  Explicitly deny the requests from `productpage` to `details`.

    Run the following command to set up the deny rule along with a handler and an instance.
    ```command
    $ istioctl create -f samples/bookinfo/kube/mixer-rule-deny-serviceaccount.yaml
    Created config denier/default/denyproductpagehandler at revision 2877836
    Created config checknothing/default/denyproductpagerequest at revision 2877837
    Created config rule/default/denyproductpage at revision 2877838
    ```
    Notice the following in the `denyproductpage` rule:
    ```plain
    match: destination.labels["app"] == "details" && source.user == "cluster.local/ns/default/sa/bookinfo-productpage"
    ```
    It matches requests coming from the service account
    "_cluster.local/ns/default/sa/bookinfo-productpage_" on the `details` service.

    > If you are using a namespace other than `default`, replace the `default` with your namespace in the value of `source.user`.

    This rule uses the `denier` adapter to deny these requests.
    The adapter always denies requests with a preconfigured status code and message.
    The status code and message are specified in the [denier](/docs/reference/config/policy-and-telemetry/adapters/denier/)
    adapter configuration.

1.  Refresh the `productpage` in your browser.

    You will see the message

    "_Error fetching product details! Sorry, product details are currently unavailable for this book._"

    in the lower left section of the page. This validates that the access from `productpage` to `details` is denied.

## Cleanup

*   Remove the mixer configuration:

    ```command
    $ istioctl delete -f samples/bookinfo/kube/mixer-rule-deny-serviceaccount.yaml
    ```

* If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/guides/bookinfo/#cleanup) instructions
  to shutdown the application.

## What's next

* Learn more about [Mixer](/docs/concepts/policies-and-telemetry/overview/) and [Mixer Config](/docs/concepts/policies-and-telemetry/config/).

* Discover the full [Attribute Vocabulary](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/).

* Understand the differences between Kubernetes network policies and Istio
  access control policies from this
  [blog](/blog/2017/0.1-using-network-policy/).

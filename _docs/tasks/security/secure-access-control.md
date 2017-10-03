---
title: Setup Secure Access Control
overview: This task shows how to securely control access to a service using service accounts.

order: 30

layout: docs
type: markdown
---
{% include home.html %}

This task shows how to securely control access to a service,
using the service accounts provided by Istio authentication.

When Istio auth is enabled, the server authenticates the client according to its certificate, and obtains the client's
service account from the certificate. The service account is in the `source.user` attribute.
For the format of the service account in Istio, please refer to the
[auth concepts]({{home}}/docs/concepts/network-and-auth/auth.html).

## Before you begin

* Setup Istio on auth-enabled Kubernetes by following the instructions in the
  [quick start]({{home}}/docs/setup/kubernetes/quick-start.html#installation-steps).
  Note that mTLS authentication should be enabled at step 4.

* Deploy the [BookInfo]({{home}}/docs/guides/bookinfo.html) sample application.

* Run the following command to create service account `bookinfo-productpage`,
  and redeploy the service `productpage` with the service account.

  ```bash
  kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/kube/bookinfo-add-serviceaccount.yaml)
  ```

  > Note: if you are using a namespace other than `default`,
    use `istioctl -n namespace ...` to specify the namespace.

## Access control using _denials_

In the [BookInfo]({{home}}/docs/guides/bookinfo.html) sample application, the `productpage` service is accessing
both `reviews` service and the `details` service. We would like the `details` service to deny the requests from
`productpage`.

1. Point your browser at the BookInfo `productpage` (http://$GATEWAY_URL/productpage).

   You should see the "Book Details" section in the lower left part of the page, including type, pages, publisher, etc.
   The `productpage` service obtains the "Book Details" information from the `details` service.

1. Explicitly deny the access to `details` service.

   Run the following command to set up the deny rule along with a handler and an instance.
   ```bash
   istioctl create -f samples/bookinfo/kube/mixer-rule-deny-serviceaccount.yaml
   ```
   You can expect to see the output similar to the following:
   ```bash
   Created config denier/default/denyproductpagehandler at revision 2877836
   Created config checknothing/default/denyproductpagerequest at revision 2877837
   Created config rule/default/denyproductpage at revision 2877838
   ```

   This rule uses the `denier` adapter to deny requests coming from the serivce account
   "_spiffe://cluster.local/ns/default/sa/bookinfo-productpage_" on the `details` service.
   The adapter always denies requests with a pre-configured status code and message.
   The status code and the message is specified in the [denier]({{home}}/docs/reference/config/mixer/adapters/denier.html)
   adapter configuration.

1. Refresh the `productpage` in your browser.

   You will see the message
   "Error fetching product details! Sorry, product details are currently unavailable for this book." in the lower left
   section.

## Cleanup

* Remove the mixer configuration:

  ```bash
  istioctl delete -f samples/bookinfo/kube/mixer-rule-deny-serviceaccount.yaml
  ```

* If you are not planning to explore any follow-on tasks, refer to the
  [BookInfo cleanup]({{home}}/docs/guides/bookinfo.html#cleanup) instructions
  to shutdown the application.

## Further reading

* Learn more about [Mixer]({{home}}/docs/concepts/policy-and-control/mixer.html) and [Mixer Config]({{home}}/docs/concepts/policy-and-control/mixer-config.html).

* Discover the full [Attribute Vocabulary]({{home}}/docs/reference/config/mixer/attribute-vocabulary.html).

* Read the reference guide to [Writing Config]({{home}}/docs/reference/writing-config.html).

* Understand the differences between Kubernetes network policies and Istio
  access control policies from this
  [blog]({{home}}/blog/using-network-policy-in-concert-with-istio.html).

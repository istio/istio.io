---
title: Enabling Simple Access Control
overview: This task shows how to use Istio to control access to a service.
          
order: 20

layout: docs
type: markdown
redirect_from: "/docs/tasks/basic-access-control.html"
---
{% include home.html %}

This task shows how to use Istio to control access to a service.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide]({{home}}/docs/setup/kubernetes/quick-start.html).

* Deploy the [BookInfo]({{home}}/docs/guides/bookinfo.html) sample application.

* Initialize the application version routing to direct `reviews` service requests from
  test user "jason" to version v2 and requests from any other user to v3.

  ```bash
  istioctl create -f samples/bookinfo/kube/route-rule-reviews-test-v2.yaml
  istioctl create -f samples/bookinfo/kube/route-rule-reviews-v3.yaml
  ```
  
  > Note: if you have conflicting rules that you set in previous tasks,
    use `istioctl replace` instead of `istioctl create`.

  > Note: if you are using a namespace other than `default`,
    use `istioctl -n namespace ...` to specify the namespace.

## Access control using _denials_ 

Using Istio you can control access to a service based on any attributes that are available within Mixer.
This simple form of access control is based on conditionally denying requests using Mixer selectors.

Consider the [BookInfo]({{home}}/docs/guides/bookinfo.html) sample application where the `ratings` service is accessed by multiple versions
of the `reviews` service. We would like to cut off access to version `v3` of the `reviews` service.

1. Point your browser at the BookInfo `productpage` (http://$GATEWAY_URL/productpage). 

   If you log in as user "jason", you should see black ratings stars with each review,
   indicating that the `ratings` service is being called by the "v2" version of the `reviews` service.
   
   If you log in as any other user (or logout) you should see red ratings stars with each review,
   indicating that the `ratings` service is being called by the "v3" version of the `reviews` service.

1. Explicitly deny access to version `v3` of the `reviews` service.

   Before setting up the deny rule, we must create a handler and an instance definition that can be used in the deny rule.
   ```yaml
   apiVersion: config.istio.io/v1alpha2
   kind: denier
   metadata:
     name: handler
     namespace: default
   spec:
     status:
       code: 7 # https://github.com/googleapis/googleapis/blob/master/google/rpc/code.proto
       message: Not allowed  # This message is sent back the client
   ---
   apiVersion: config.istio.io/v1alpha2
   kind: checknothing
   metadata:
     name: denyrequest
     namespace: default
   spec:
   ```
   Save the file as mixer-rule-ratings-denial.yaml and run
   ```bash
   istioctl create -f mixer-rule-ratings-denial.yaml
   ```
   You can expect to see the following output
   ```bash
   denier "denyall" created
   checknothing "denyrequest" created
   ```

   Now create the following rule using the above method
   ```yaml
   apiVersion: config.istio.io/v1alpha2
   kind: rule
   metadata:
     name: denyreviewsv3
     namespace: default
   spec:
     match: destination.labels["app"] == "ratings" && source.labels["app"]=="reviews" && source.labels["version"] == "v3"
     actions:
     - handler: denyall.denier
       instances:
       - denyrequest.checknothing
   ```

   This rule uses the `denier` adapter to deny requests coming from version `v3` of the reviews service.
   The adapter always denies requests with a pre-configured status code and message.
   The status code and the message is specified in the [denier]({{home}}/docs/reference/config/mixer/adapters/denier.html)
   adapter configuration.
  
1. Refresh the `productpage` in your browser.

   If you are logged out or logged in as any user other than "jason" you will no longer see red ratings stars because
   the `reviews:v3` service has been denied access to the `ratings` service.
   Notice, however, that if you log in as user "jason" (the `reviews:v2` user) you continue to see
   the black ratings stars.

## Access control using _whitelists_ 

Istio also supports attribute-based whitelists and blacklists.

1. Add an adapter definition for the [`listchecker`]({{home}}/docs/reference/config/mixer/adapters/list.html)
   adapter that lists versions `v1, v2`:

   ```yaml
   apiVersion: config.istio.io/v1alpha2
   kind: listchecker
   metadata:
     name: staticversion
     namespace: default
   spec:
     # providerUrl: ordinarily black and white lists are maintained
     # externally and fetched asynchronously using the providerUrl.
     overrides: ["v1", "v2"]  # overrides provide a static list
     blacklist: false
   ```

2. Extract the version label by creating an instance of the [`listentry`]({{home}}/docs/reference/config/mixer/template/listentry.html) template:

   ```yaml
   apiVersion: config.istio.io/v1alpha2
   kind: listentry
   metadata:
     name: appversion
     namespace: default
   spec:
     value: source.labels["version"]
   ```

3. Enable `whitelist` checking for the ratings service:

   ```yaml
   apiVersion: config.istio.io/v1alpha2
   kind: rule
   metadata:
     name: checkversion
     namespace: default
   spec:
     match: destination.labels["app"] == "ratings"
     actions:
     - handler: staticversion.listchecker
       instances:
       - appversion.listentry
   ```

## Cleanup

* Remove the mixer configuration:

  ```bash
  istioctl delete -f /path/to/file.yaml
  ```

* Remove the application routing rules:

  ```
  istioctl delete -f samples/bookinfo/kube/route-rule-reviews-test-v2.yaml
  istioctl delete -f samples/bookinfo/kube/route-rule-reviews-v3.yaml
  ```

## What's next

* Learn more about [Mixer]({{home}}/docs/concepts/policy-and-control/mixer.html) and [Mixer Config]({{home}}/docs/concepts/policy-and-control/mixer-config.html).

* Discover the full [Attribute Vocabulary]({{home}}/docs/reference/config/mixer/attribute-vocabulary.html).

* Read the reference guide to [Writing Config]({{home}}/docs/reference/writing-config.html).

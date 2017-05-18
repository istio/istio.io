---
title: Enabling Simple Access Control
overview: This task shows how to use Istio to control access to a service.
          
order: 90

layout: docs
type: markdown
---
{% include home.html %}

This task shows how to use Istio to control access to a service.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](./installing-istio.html).

* Deploy the [BookInfo]({{home}}/docs/samples/bookinfo.html) sample application.

* Initialize the application version routing to direct `reviews` service requests from
  test user "jason" to version v2 and requests from any other user to v3.

  ```bash
  istioctl create -f samples/apps/bookinfo/route-rule-reviews-test-v2.yaml
  istioctl create -f samples/apps/bookinfo/route-rule-reviews-v3.yaml
  ```
  
  > Note: if you have conflicting rule that you set in previous tasks,
    use `istioctl replace` instead of `istioctl create`.

## Access control using _denials_ 

Using Istio you can control access to a service based on any attributes that are available within Mixer.
This simple form of access control is based on conditionally denying requests using Mixer selectors.

Consider the [BookInfo]({{home}}/docs/samples/bookinfo.html) sample application where the `ratings` service is accessed by multiple versions
of the `reviews` service. We would like to cut off access to version `v3` of the `reviews` service.

1. Point your browser at the Bookinfo `productpage` (http://$GATEWAY_URL/productpage). 

   If you log in as user "jason", you should see black ratings stars with each review,
   indicating that the `ratings` service is being called by the "v2" version of the `reviews` service.
   
   If you log in as any other user (or logout) you should see red ratings stars with each review,
   indicating that the `ratings` service is being called by the "v3" version of the `reviews` service.

1. Explicitly deny access to version `v3` of the `reviews` service. 

   ```bash
   istioctl mixer rule create global ratings.default.svc.cluster.local -f samples/apps/bookinfo/mixer-rule-ratings-denial.yaml
   ```

   This command sets configuration for `subject=ratings.default.svc.cluster.local`. 
   You can display the current configuration with the following command:

   ```
   istioctl mixer rule get global ratings.default.svc.cluster.local
   ```

   which should produce:

   ```yaml
   rules:
   - aspects:
     - kind: denials
     selector: source.labels["app"]=="reviews" && source.labels["version"] == "v3"
   ```

   This rule uses the `denials` aspect to deny requests coming from version `v3` of the reviews service.
   The `denials` aspect always denies requests with a pre-configured status code and message.
   The status code and the message is specified in the [DenyChecker]({{home}}/docs/reference/config/mixer/adapters/denyChecker.html)
   adapter configuration.
  
1. Refresh the `productpage` in your browser.

   If you are logged out or logged in as any user other than "jason" you will no longer see red ratings stars because
   the `reviews:v3` service has been denied access to the `ratings` service.
   Notice, however, that if you log in as user "jason" (the `reviews:v2` user) you continue to see
   the black ratings stars.

## Access control using _whitelists_ 

Istio also supports attribute-based white and blacklists.
Using a whitelist is a two step process.

1. Add an adapter definition for the [`genericListChecker`]({{home}}/docs/reference/config/mixer/adapters/genericListChecker.html) 
   adapter that lists versions `v1, v2`:

   ```yaml
   - name: versionList
     impl: genericListChecker
     params:
       listEntries: ["v1", "v2"]
   ```

2. Enable `whitelist` checking by using the [`lists`]({{home}}/docs/reference/config/mixer/aspects/lists.html) aspect:

   ```yaml
   rules:
     aspects:
     - kind: lists
       adapter: versionList
       params:
         blacklist: false
         checkExpression: source.labels["version"] 
   ``` 

   `checkExpression` is evaluated and checked against the list `[v1, v2]`. The check behavior can be changed to a blacklist by specifying
   `blacklist: true`. The expression evaluator returns the value of the `version` label as specified by the `checkExpression` key.

The current version of `istioctl` does not yet support
pushing adapter configurations like the one in step 1.
There is, however, a [workaround]({{home}}/docs/concepts/policy-and-control/mixer-aspect-config.html#pushing-configuration)
that you can use if you want to try it out anyway.

## Cleanup

* Remove the mixer configuration rule:

  ```bash
  istioctl mixer rule create global ratings.default.svc.cluster.local -f samples/apps/bookinfo/mixer-rule-empty-rule.yaml
  ```

  > Note: removing a rule by setting an empty rule list is a temporary workaround because `istioctl delete` does not
    yet support mixer rules.

* Remove the application routing rules:

  ```
  istioctl delete -f samples/apps/bookinfo/route-rule-reviews-test-v2.yaml
  istioctl delete -f samples/apps/bookinfo/route-rule-reviews-v3.yaml
  ```

## What's next

* Learn more about [Mixer]({{home}}/docs/concepts/policy-and-control/mixer.html) and [Mixer Config]({{home}}/docs/concepts/policy-and-control/mixer-config.html).

* Discover the full [Attribute Vocabulary]({{home}}/docs/reference/config/mixer/attribute-vocabulary.html).

* Read the reference guide to [Writing Config]({{home}}/docs/reference/writing-config.html).

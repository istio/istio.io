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

* Initialize the application version routing by either first performing the
  [request routing](./request-routing.html) task or by running the following
  commands:
  
  ```bash
  istioctl create -f route-rule-all-v1.yaml
  istioctl replace -f route-rule-reviews-v2-v3.yaml
  ```
* Ensure that you can use [istioctl mixer]({{home}}/docs/reference/commands/istioctl/istioctl_mixer.html#synopsis) by setting up port forwarding if needed.

## Access control using _denials_ 

Using Istio you can control access to a service based on any attributes that are available within Mixer.
This simple form of access control is based on conditionally denying requests using Mixer selectors.

Consider the [BookInfo]({{home}}/docs/samples/bookinfo.html) sample application where the `ratings` service is accessed by multiple versions
of the `reviews` service. We would like to cut off access to version `v3` of this service.

1. Check that versions `v2,v3` of the `reviews` service can access the `ratings` service. 
   You should see red and black stars alternate when repeatedly visiting 
   `http://$GATEWAY_URL/productpage` in a browser. 

2. Explicitly deny access to version `v3` of the `reviews` service. 

  ```bash
  istioctl mixer rule create global ratings.default.svc.cluster.local -f deny-reviews.yml
  ```
  where deny-reviews.yml is 
   
  ```yaml
  rules:
  - selector: source.labels["app"]=="reviews" && source.labels["version"] == "v3"  
    aspects:
    - kind: denials
  ```
  This rule uses the `denials` aspect to deny requests coming from version `v3` of the reviews service.
  The `denials` aspect always denies requests with a pre-configured status code and message.
  The status code and the message is specified in the [DenyChecker]({{home}}/docs/reference/api/adapters/denyChecker.html)
  adapter configuration.

## Access control using _whitelists_ 

Istio also supports attribute-based white and blacklists.
Using a whitelist is a two step process.

1. Add an adapter definition for the [`genericListChecker`]({{home}}/docs/reference/api/adapters/genericListChecker.html) adapter that lists versions `v1, v2`:

    ```yaml
    - name: versionList
      impl: genericListChecker
      params:
        listEntries: ["v1", "v2"]
    ```

2. Enable `whitelist` checking by using the [`lists`]({{home}}/docs/reference/api/mixer-aspects.html#lists) aspect:

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


## What's next

* Learn more about [Mixer]({{home}}/docs/concepts/policy-and-control/mixer.html) and [Mixer Config]({{home}}/docs/concepts/policy-and-control/mixer-config.html).
* Discover the full [Attribute Vocabulary]({{home}}/docs/reference/attribute-vocabulary.html).
* Read the reference guide to [Writing Config]({{home}}/docs/reference/writing-config.html).

---
title: Enabling Rate Limits
description: This task shows you how to use Istio to dynamically limit the traffic to a service.
weight: 10
keywords: [policies,quotas]
aliases:
    - /docs/tasks/rate-limiting.html
---

This task shows you how to use Istio to dynamically limit the traffic to a
service.

## Before you begin

* Setup Istio in a Kubernetes cluster by following the quick start instructions
  in the [Installation guide](/docs/setup/kubernetes/quick-start/).

* Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

* Initialize the application version routing to direct `reviews` service
  requests from test user "jason" to version v2 and requests from any other
  user to v3.

  {{< text bash >}}
  $ istioctl create -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
  {{< /text >}}

   and then run the following command:

  {{< text bash >}}
  $ istioctl replace -f @samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml@
  {{< /text >}}

> If you have a conflicting rule that you set in previous tasks,
use `istioctl replace` instead of `istioctl create`.

## Rate limits

Istio enables you to rate limit traffic to a service.

Consider `ratings` as an external paid service like Rotten Tomatoes® with
`1qps` free quota. Using Istio we can ensure that `1qps` is not breached.

1. Point your browser at the Bookinfo `productpage`
   (http://$GATEWAY_URL/productpage).

    If you log in as user "jason", you should see black ratings stars with
    each review, indicating that the `ratings` service is being called by the
    "v2" version of the `reviews` service.

    If you log in as any other user (or logout) you should see red ratings
    stars with each review, indicating that the `ratings` service is being
    called by the "v3" version of the `reviews` service.

1. Configure `memquota`, `quota`, `rule`, `QuotaSpec`, `QuotaSpecBinding` to
   enable rate limiting.

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/policy/mixer-rule-ratings-ratelimit.yaml@
    {{< /text >}}

1. Confirm the `memquota` was created:

    {{< text bash yaml >}}
    $ kubectl -n istio-system get memquota handler -o yaml
    apiVersion: config.istio.io/v1alpha2
    kind: memquota
    metadata:
      name: handler
      namespace: istio-system
    spec:
      quotas:
      - name: requestcount.quota.istio-system
        maxAmount: 5000
        validDuration: 1s
        overrides:
        - dimensions:
            destination: ratings
            source: reviews
            sourceVersion: v3
          maxAmount: 1
          validDuration: 5s
        - dimensions:
            destination: ratings
          maxAmount: 5
          validDuration: 10s
    {{< /text >}}

  The `memquota` defines 3 different rate limit schemes. The default, if no
  overrides match, is `5000` requests per `1s`. Two overrides are also
  defined. The first is `1` request every `5s` if the `destination` is
  `ratings`, the source is `reviews`, and the `sourceVersion` is `v3`. The
  second is `5` request every `10s` if the `destination` is `ratings`. The
  first matching override is picked (reading from top to bottom).

1. Confirm the `quota` was created:

    {{< text bash yaml >}}
    $ kubectl -n istio-system get quotas requestcount -o yaml
    apiVersion: config.istio.io/v1alpha2
    kind: quota
    metadata:
      name: requestcount
      namespace: istio-system
    spec:
      dimensions:
        source: source.labels["app"] | source.service | "unknown"
        sourceVersion: source.labels["version"] | "unknown"
        destination: destination.labels["app"] | destination.service | "unknown"
        destinationVersion: destination.labels["version"] | "unknown"
    {{< /text >}}

    The `quota` template defines 4 `dimensions` that are used by `memquota` to
    set overrides on request that match certain attributes. `destination` will
    be set to the first non-empty value in `destination.labels["app"]`,
    `destination.service`, or `"unknown"`. More info on expressions can be
    found
    [here](/docs/reference/config/policy-and-telemetry/expression-language/).

1. Confirm the `rule` was created:

    {{< text bash yaml >}}
    $ kubectl -n istio-system get rules quota -o yaml
    apiVersion: config.istio.io/v1alpha2
    kind: rule
    metadata:
      name: quota
      namespace: istio-system
    spec:
      actions:
      - handler: handler.memquota
        instances:
        - requestcount.quota
    {{< /text >}}

    The `rule` tells mixer to invoke `handler.memquota` handler (created
    above) and pass it the object constructed using the instance
    `requestcount.quota` (also created above). This effectively maps the
    dimensions from the `quota` template to `memquota` handler.

1. Confirm the `QuotaSpec` was created:

    {{< text bash yaml >}}
    $ kubectl -n istio-system get QuotaSpec request-count -o yaml
    apiVersion: config.istio.io/v1alpha2
    kind: QuotaSpec
    metadata:
      name: request-count
      namespace: istio-system
    spec:
      rules:
      - quotas:
        - charge: "1"
          quota: requestcount
    {{< /text >}}

    This `QuotaSpec` defines the requestcount `quota` we created above with a
    charge of `1`.

1. Confirm the `QuotaSpecBinding` was created:

    {{< text bash yaml >}}
    $ kubectl -n istio-system get QuotaSpecBinding request-count -o yaml
    kind: QuotaSpecBinding
    metadata:
      name: request-count
      namespace: istio-system
    spec:
      quotaSpecs:
      - name: request-count
        namespace: istio-system
      services:
      - name: ratings
        namespace: default
      - name: reviews
        namespace: default
      - name: details
        namespace: default
      - name: productpage
        namespace: default
    {{< /text >}}

    This `QuotaSpecBinding` binds the `QuotaSpec` we created above to the
    services we want to apply it to. Note we have to define the namespace for
    each service since it is not in the same namespace this `QuotaSpecBinding`
    resource was deployed into.

1. Refresh the `productpage` in your browser.

    If you are logged out, reviews-v3 service is rate limited to 1 request
    every 5 seconds. If you keep refreshing the page the stars should only
    load around once every 5 seconds.

    If you log in as user "jason", reviews-v2 service is rate limited to 5
    requests every 10 seconds. If you keep refreshing the page the stars
    should only load 5 times every 10 seconds.

    For all other services the default 5000qps rate limit will apply.

## Conditional rate limits

In the previous example we applied a rate limit to the `ratings` service
without regard to non-dimension attributes. It is possible to conditionally
apply rate limits based on arbitrary attributes using a match condition in
the quota rule.

For example, consider the following configuration:

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: rule
metadata:
  name: quota
  namespace: istio-system
spec:
  match: source.namespace != destination.namespace
  actions:
  - handler: handler.memquota
    instances:
    - requestcount.quota
{{< /text >}}

This configuration applies the quota rule to requests whose source and
destination namespaces are different.

## Understanding rate limits

In the preceding examples we saw how Mixer applies rate limits to requests
that match certain conditions.

Every named quota instance like `requestcount` represents a set of counters.
The set is defined by a Cartesian product of all quota dimensions. If the
number of requests in the last `expiration` duration exceed `maxAmount`,
Mixer returns a `RESOURCE_EXHAUSTED` message to the proxy. The proxy in turn
returns status `HTTP 429` to the caller.

The `memquota` adapter uses a sliding window of sub second resolution to
enforce rate limits.

The `maxAmount` in the adapter configuration sets the default limit for all
counters associated with a quota instance. This default limit applies if a
quota override does not match the request. Memquota selects the first
override that matches a request. An override need not specify all quota
dimensions. In the example, the `0.2qps` override is selected by matching
only three out of four quota dimensions.

If you would like the above policies enforced for a given namespace instead
of the entire Istio mesh, you can replace all occurrences of istio-system
with the given namespace.

## Cleanup

* Remove the rate limit configuration:

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/policy/mixer-rule-ratings-ratelimit.yaml@
    {{< /text >}}

* Remove the application routing rules:

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

* If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
  to shutdown the application.

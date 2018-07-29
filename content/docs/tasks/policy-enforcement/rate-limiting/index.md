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

1. Setup Istio in a Kubernetes cluster by following the instructions in the
   [Installation Guide](/docs/setup/kubernetes/quick-start/).

1. Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

    The Bookinfo sample deploys 3 versions of the `reviews` service:

    * Version v1 doesn’t call the `ratings` service.
    * Version v2 calls the `ratings` service, and displays each rating as 1 to 5 black stars.
    * Version v3 calls the `ratings` service, and displays each rating as 1 to 5 red stars.

    You need to set a default route to one of the versions. Otherwise, when you send requests to the `reviews` service, Istio routes requests to all available versions randomly, and sometimes the output contains star ratings and sometimes it doesn't.

1. Set the default version for all services to v1. If you’ve already created route rules for the sample, use `replace` rather than `create` in the following command.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. Initialize application version routing on the `reviews` service to
   direct requests from the test user "jason" to version v2 and requests from any other user to v3.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml@
    {{< /text >}}

## Rate limits

In this task, you configure Istio to rate limit traffic to the `ratings`
service. Consider `ratings` as an external paid service like Rotten Tomatoes®
with 1 qps free quota. Using Istio, you can ensure that 1 qps is not exceeded.

For convenience, you configure the
[memory quota](/docs/reference/config/policy-and-telemetry/adapters/memquota/)
(`memquota`) adapter to enable rate limiting. On a production system, however,
you need [Redis](https://redis.io/), and you configure the [Redis
quota](/docs/reference/config/policy-and-telemetry/adapters/redisquota/)
(`redisquota`) adapter. Both the `memquota` and `redisquota` adapters support
the [quota template](/docs/reference/config/policy-and-telemetry/templates/quota/),
so the configuration to enable rate limiting on both adapters is the same.

1. Point your browser at the Bookinfo `productpage`
   (`http://$GATEWAY_URL/productpage`).

    * If you log in as user "jason", you should see black ratings stars with
    each review, indicating that the `ratings` service is being called by the
    "v2" version of the `reviews` service.

    * If you log in as any other user, you should see red ratings
    stars with each review, indicating that the `ratings` service is being
    called by the "v3" version of the `reviews` service.

1. Configure `memquota`, `quota`, `rule`, `QuotaSpec`, `QuotaSpecBinding` to
   enable rate limiting.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-ratings-ratelimit.yaml@
    {{< /text >}}

1. Confirm the `memquota` handler was created:

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

    The `memquota` handler defines 3 different rate limit schemes. The default,
    if no overrides match, is `5000` requests per one second (`1s`). Two
    overrides are also defined:

    * The first is `1` request (the `maxAmount` field) every `5s` (the
    `validDuration` field), if the `destination` is `ratings`, the `source` is
     `reviews`, and the `sourceVersion` is `v3`.
    * The second is `5` requests every `10s`, if the `destination` is `ratings`.

    When a request is sent to the `ratings` service, the first matching override
    is picked (reading from top to bottom).

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
        source: source.labels["app"] | "unknown"
        sourceVersion: source.labels["version"] | "unknown"
        destination: destination.labels["app"] | destination.service.host | "unknown"
        destinationVersion: destination.labels["version"] | "unknown"
    {{< /text >}}

    The `quota` template defines four dimensions that are used by `memquota`
    to set overrides on requests that match certain attributes. The
    `destination` will be set to the first non-empty value in
    `destination.labels["app"]`, `destination.service.host`, or `"unknown"`. For
     more information on expressions, see [Expression
    Language](/docs/reference/config/policy-and-telemetry/expression-language/).

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

    The `rule` tells Mixer to invoke the `handler.memquota` handler (created
    above) and pass it the object constructed using the instance
    `requestcount.quota` (also created above). This maps the
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

    This `QuotaSpec` defines the `requestcount quota` you created above with a
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

    This `QuotaSpecBinding` binds the `QuotaSpec` you created above to the
    services you want to apply it to. You have to define the namespace for
    each service since it is not in the same namespace this `QuotaSpecBinding`
    resource was deployed into.

1. Refresh the product page in your browser.

    * If you are logged out, `reviews-v3` service is rate limited to 1 request
    every 5 seconds. If you keep refreshing the page, the stars should only
    load around once every 5 seconds.

    * If you log in as user "jason", `reviews-v2` service is rate limited to 5
    requests every 10 seconds. If you keep refreshing the page, the stars
    should only load 5 times every 10 seconds.

    * For all other services, the default 5000 qps rate limit will apply.

## Conditional rate limits

In the previous example you applied a rate limit to the `ratings` service
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

In the preceding examples you saw how Mixer applies rate limits to requests
that match certain conditions.

Every named quota instance like `requestcount` represents a set of counters.
The set is defined by a Cartesian product of all quota dimensions. If the
number of requests in the last `expiration` duration exceed `maxAmount`,
Mixer returns a `RESOURCE_EXHAUSTED` message to the Envoy proxy, and Envoy
returns status `HTTP 429` to the caller.

The `memquota` adapter uses a sliding window of sub-second resolution to
enforce rate limits.

The `maxAmount` in the adapter configuration sets the default limit for all
counters associated with a quota instance. This default limit applies if a quota
override does not match the request. The `memquota` adapter selects the first
override that matches a request. An override need not specify all quota
dimensions. In the example, the 0.2 qps override is selected by matching only
three out of four quota dimensions.

If you want the policies enforced for a given namespace instead of the entire
Istio mesh, you can replace all occurrences of istio-system with the given
namespace.

## Cleanup

1. Remove the rate limit configuration:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-ratings-ratelimit.yaml@
    {{< /text >}}

1. Remove the application routing rules:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. If you are not planning to explore any follow-on tasks, refer to the
  [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
  to shutdown the application.

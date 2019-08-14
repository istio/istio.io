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
   [Installation Guide](/docs/setup/kubernetes/install/kubernetes/).

    {{< warning >}}
    Policy enforcement **must** be enabled in your cluster for this task. Follow the steps in
    [Enabling Policy Enforcement](/docs/tasks/policy-enforcement/enabling-policy/) to ensure that policy enforcement is enabled.
    {{< /warning >}}

1. Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

    The Bookinfo sample deploys 3 versions of the `reviews` service:

    * Version v1 doesn’t call the `ratings` service.
    * Version v2 calls the `ratings` service, and displays each rating as 1 to 5 black stars.
    * Version v3 calls the `ratings` service, and displays each rating as 1 to 5 red stars.

    You need to set a default route to one of the versions. Otherwise, when you send requests to the `reviews` service, Istio routes requests to all available versions randomly, and sometimes the output contains star ratings and sometimes it doesn't.

1. Set the default version for all services to v1.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

## Rate limits

In this task, you configure Istio to rate limit traffic to `productpage` based on the IP address
of the originating client. You will use `X-Forwarded-For` request header as the client
IP address. You will also use a conditional rate limit that exempts logged in users.

For convenience, you configure the
[memory quota](/docs/reference/config/policy-and-telemetry/adapters/memquota/)
(`memquota`) adapter to enable rate limiting. On a production system, however,
you need [Redis](http://redis.io/), and you configure the [Redis
quota](/docs/reference/config/policy-and-telemetry/adapters/redisquota/)
(`redisquota`) adapter. Both the `memquota` and `redisquota` adapters support
the [quota template](/docs/reference/config/policy-and-telemetry/templates/quota/),
so the configuration to enable rate limiting on both adapters is the same.

1. Rate limit configuration is split into 2 parts.
    * Client Side
        * `QuotaSpec` defines quota name and amount that the client should request.
        * `QuotaSpecBinding` conditionally associates `QuotaSpec` with one or more services.
    * Mixer Side
        * `quota instance` defines how quota is dimensioned by Mixer.
        * `memquota handler` defines `memquota` adapter configuration.
        * `quota rule` defines when quota instance is dispatched to the `memquota` adapter.

    Run the following command to enable rate limits using `memquota`:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-productpage-ratelimit.yaml@
    {{< /text >}}

    {{< warning >}}
    If you use Istio 1.1.2 or prior, please use the following configuration instead:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-productpage-ratelimit-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

    The `memquota` handler defines 4 different rate limit schemes. The default,
    if no overrides match, is `500` requests per one second (`1s`). Two
    overrides are also defined:

    * The first is `1` request (the `maxAmount` field) every `5s` (the
    `validDuration` field), if the `destination` is `reviews`.
    * The second is `500` requests every `1s`, if the destination is `productpage`
     and source is `10.28.11.20`
    * The third is `2` requests every `5s`, if the `destination` is `productpage`.

    When a request is processed, the first matching override is picked (reading from top to bottom).

    Or

    Run the following command to enable rate limits using `redisquota`:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-productpage-redis-quota-rolling-window.yaml@
    {{< /text >}}

    _Note:_ Replace [rate_limit_algorithm](/docs/reference/config/policy-and-telemetry/adapters/redisquota/#Params-QuotaAlgorithm),
    [redis_server_url](/docs/reference/config/policy-and-telemetry/adapters/redisquota/#Params) with values for your configuration.

    The `redisquota` handler defines 4 different rate limit schemes. The default,
    if no overrides match, is `500` requests per one second (`1s`). It is using `ROLLING_WINDOW`
    algorithm for quota check and thus define `bucketDuration` of 500ms for `ROLLING_WINDOW`
    algorithm. Three overrides are also defined:

    * The first is `1` request (the `maxAmount` field), if the `destination` is `reviews`.
    * The second is `500`, if the destination is `productpage` and source
      is `10.28.11.20`
    * The third is `2`, if the `destination` is `productpage`.

    When a request is processed, the first matching override is picked (reading from top to bottom).

1. Confirm the `quota instance` was created:

    {{< text bash >}}
    $ kubectl -n istio-system get instance requestcountquota -o yaml
    {{< /text >}}

    The `quota` template defines three dimensions that are used by `memquota` or `redisquota`
    to set overrides on requests that match certain attributes. The
    `destination` will be set to the first non-empty value in
    `destination.labels["app"]`, `destination.service.host`, or `"unknown"`. For
     more information on expressions, see [Expression
    Language](/docs/reference/config/policy-and-telemetry/expression-language/).

1. Confirm the `quota rule` was created:

    {{< text bash >}}
    $ kubectl -n istio-system get rule quota -o yaml
    {{< /text >}}

    The `rule` tells Mixer to invoke the `memquota` or `redisquota` handler (created
    above) and pass it the object constructed using the instance
    `requestcountquota` (also created above). This maps the
    dimensions from the `quota` template to `memquota` or `redisquota` handler.

1. Confirm the `QuotaSpec` was created:

    {{< text bash >}}
    $ kubectl -n istio-system get QuotaSpec request-count -o yaml
    {{< /text >}}

    This `QuotaSpec` defines the `requestcountquota` you created above with a
    charge of `1`.

1. Confirm the `QuotaSpecBinding` was created:

    {{< text bash >}}
    $ kubectl -n istio-system get QuotaSpecBinding request-count -o yaml
    {{< /text >}}

    This `QuotaSpecBinding` binds the `QuotaSpec` you created above to the
    services you want to apply it to. `productpage` is explicitly bound to `request-count`, note
    that you must define the namespace since it differs from the namespace of the `QuotaSpecBinding`.
    If the last line is uncommented, `service: '*'` binds all services to the `QuotaSpec`
    making the first entry redundant.

1. Refresh the product page in your browser.

    `request-count` quota applies to `productpage` and it permits 2 requests
    every 5 seconds. If you keep refreshing the page you should see
    `RESOURCE_EXHAUSTED:Quota is exhausted for: requestcount`.

## Conditional rate limits

In the above example we have effectively rate limited `productpage` at `2 rps` per client IP.
Consider a scenario where you would like to exempt clients from this rate limit if a user is logged in.
In the `bookinfo` example, we use cookie `session=<sessionid>` to denote a logged in user.
In a realistic scenario you may use a `jwt` token for this purpose.

You can update the `quota rule` by adding a match condition based on the `cookie`.

{{< text bash >}}
$ kubectl -n istio-system edit rules quota
{{< /text >}}

{{< text yaml >}}
...
spec:
  match: match(request.headers["cookie"], "session=*") == false
  actions:
...
{{< /text >}}

{{< warning >}}
Don't enable [chrome preload](https://support.google.com/chrome/answer/114836?hl=en&co=GENIE.Platform=Desktop) as it can
preload cookies and fail this task.

{{< /warning >}}

`memquota` or `redisquota` adapter is now dispatched only if `session=<sessionid>` cookie is absent from the request.
This ensures that a logged in user is not subject to this quota.

1.  Verify that rate limit does not apply to a logged in user.

    Log in as `jason` and repeatedly refresh the `productpage`. Now you should be able to do this without a problem.

1.  Verify that rate limit *does* apply when not logged in.

    Logout as `jason` and repeatedly refresh the `productpage`.
    You should again see `RESOURCE_EXHAUSTED:Quota is exhausted for: requestcount`.

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

The `redisquota` adapter can be configured to use either the [`ROLLING_WINDOW` or `FIXED_WINDOW`](/docs/reference/config/policy-and-telemetry/adapters/redisquota/#Params-QuotaAlgorithm)
algorithms to enforce rate limits.

The `maxAmount` in the adapter configuration sets the default limit for all
counters associated with a quota instance. This default limit applies if a quota
override does not match the request. The `memquota/redisquota` adapter selects the first
override that matches a request. An override need not specify all quota
dimensions. In the example, the 0.2 qps override is selected by matching only
three out of four quota dimensions.

If you want the policies enforced for a given namespace instead of the entire
Istio mesh, you can replace all occurrences of `istio-system` with the given
namespace.

## Cleanup

1. If using `memquota`, remove the `memquota` rate limit configuration:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-productpage-ratelimit.yaml@
    {{< /text >}}

    If you are using Istio 1.1.2 or prior:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-productpage-ratelimit-crd.yaml@
    {{< /text >}}

    Or

    If using `redisquota`, remove the `redisquota` rate limit configuration:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-productpage-redis-quota-rolling-window.yaml@
    {{< /text >}}

1. Remove the application routing rules:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. If you are not planning to explore any follow-on tasks, refer to the
   [Bookinfo cleanup](/docs/examples/bookinfo/#cleanup) instructions
   to shutdown the application.

---
title: Handling Failures
description: An overview of failure recovery capabilities in Envoy that can be leveraged by unmodified applications to improve robustness and prevent cascading failures.
weight: 30
---

Envoy provides a set of out-of-the-box _opt-in_ failure recovery features
that can be taken advantage of by the services in an application. Features
include:

1. Timeouts

1. Bounded retries with timeout budgets and variable jitter between retries

1. Limits on number of concurrent connections and requests to upstream services

1. Active (periodic) health checks on each member of the load balancing pool

1. Fine-grained circuit breakers (passive health checks) -- applied per
instance in the load balancing pool

These features can be dynamically configured at runtime through
[Istio's traffic management rules](/docs/concepts/traffic-management/rules-configuration/).

The jitter between retries minimizes the impact of retries on an overloaded
upstream service, while timeout budgets ensure that the calling service
gets a response (success/failure) within a predictable time frame.

A combination of active and passive health checks (4 and 5 above)
minimizes the chances of accessing an unhealthy instance in the load
balancing pool. When combined with platform-level health checks (such as
those supported by Kubernetes or Mesos), applications can ensure that
unhealthy pods/containers/VMs can be quickly weeded out of the service
mesh, minimizing the request failures and impact on latency.

Together, these features enable the service mesh to tolerate failing nodes
and prevent localized failures from cascading instability to other nodes.

## Fine tuning

Istio's traffic management rules allow
operators to set global defaults for failure recovery per
service/version. However, consumers of a service can also override
[timeout](/docs/reference/config/istio.routing.v1alpha1/#HTTPTimeout)
and
[retry](/docs/reference/config/istio.routing.v1alpha1/#HTTPRetry)
defaults by providing request-level overrides through special HTTP headers.
With the Envoy proxy implementation, the headers are `x-envoy-upstream-rq-timeout-ms` and
`x-envoy-max-retries`, respectively.

## FAQ

Q: *Do applications still handle failures when running in Istio?*

Yes. Istio improves the reliability and availability of services in the
mesh. However, **applications need to handle the failure (errors)
and take appropriate fallback actions**. For example, when all instances in
a load balancing pool have failed, Envoy will return HTTP 503. It is the
responsibility of the application to implement any fallback logic that is
needed to handle the HTTP 503 error code from an upstream service.

Q: *Will Envoy's failure recovery features break applications that already
use fault tolerance libraries (e.g. [Hystrix](https://github.com/Netflix/Hystrix))?*

No. Envoy is completely transparent to the application. A failure response
returned by Envoy would not be distinguishable from a failure response
returned by the upstream service to which the call was made.

Q: *How will failures be handled when using application-level libraries and
Envoy at the same time?*

Given two failure recovery policies for the same destination service (e.g.,
two timeouts -- one set in Envoy and another in application's library), **the
more restrictive of the two will be triggered when failures occur**. For
example, if the application sets a 5 second timeout for an API call to a
service, while the operator has configured a 10 second timeout, the
application's timeout will kick in first. Similarly, if Envoy's circuit
breaker triggers before the application's circuit breaker, API calls to the
service will get a 503 from Envoy.

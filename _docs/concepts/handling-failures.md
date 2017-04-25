---
category: Concepts
title: Handling Failures

parent: Traffic Management
order: 30

bodyclass: docs
layout: docs
type: markdown
---

Envoy sidecar/proxy provides a set of out-of-the-box _opt-in_ failure recovery features
that can be taken advantage of by the services in an application. Features
include:

1. Timeouts
2. Bounded retries with timeout budgets and variable jitter between retries
3. Limits on number of concurrent connections and requests to upstream services
4. Active health checks on each member of the load balancing pool
5. Fine-grained circuit breakers -- applied per instance in the load
   balancing pool

These features can be dynamically configured at runtime through
[Istio's traffic management rules](../tasks/timeouts-retries-circuit-breakers.html).

The jitter between retries minimizes the impact of retries on an overloaded
upstream service, while timeout budgets ensure that the calling service
gets a response (success/failure) within a predictable timeframe.

A combination of (periodic) active health checks and circuit breakers
minimizes the chances of accessing an unhealthy instance in the load
balancing pool. When combined with platform-level health checks (such as
those supported in Kubernetes or Mesos), applications can ensure that
unhealthy pods/containers/VMs can be quickly weeded out of the service
mesh, minimizing the overall latency impact.

Together, these features enable services in the Istio service mesh to fail
fast and prevent cascading failures.

## Fine tuning 

Istio's traffic management rules allow
operators to set global defaults for failure recovery per
service/version. However, consumers of a service can override these
defaults by providing
[request-level overrides through special HTTP headers](../tasks/timeouts-retries-circuit-breakers.html).

## Compatibility: Hystrix & Envoy

_Will Envoy's failure recovery features break applications that already use
[Hystrix](https://github.com/Netflix/Hystrix) like libraries?_ The answer
is **no**. Envoy is completely transparent to the application. A failure
response returned by Envoy would not be distinguishable from a failure
response returned by the upstream service to which the call was made.

Given two failure recovery policies for the same destination service (e.g.,
two timeouts -- one set in Envoy and another in Hystrix library), **the
more restrictive of the two will be triggered when failures occur**. For
example, if the application sets a 5 second timeout for an API call to a
service, while the operator has configured a 10 second timeout, the
application's timeout will kick in first. Similarly, if Envoy's circuit
breaker triggers before the application's circuit breaker, API calls to the
service will get a 503 from Envoy. When in doubt, developers can always
disable Istio's failure recovery features.


## Responsibilities: App vs Istio

While Istio allows operators to quickly detect and recover from failures,
recovery will never be complete without application involvement. _It is the
responsibility of the application to implement any fallback logic that is
needed to handle a fault such as timeout/HTTP 503_. For example, Hystrix
implementations often have a callback to a fallback function that returns a
default value (e.g., generalized recommendation) when an API call to an
upstream service (e.g., personalized recommendation) fails.

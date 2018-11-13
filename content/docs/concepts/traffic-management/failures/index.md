---
title: Handling Failures
description: Describes the failure behavior of Istio and provides examples on how to handle failures.
weight: 9
keywords: [failure handling, timeouts, retries, limit connections, health checks, troubleshooting, configuration, errors]
aliases:
---

Envoy provides a set of out-of-the-box _opt-in_ failure recovery features
that can be taken advantage of by the services in an application. Features
include:

1. [Timeouts](#timeouts)

1. [Retries](#retries): Bounded with timeout budgets and with variable jitter

1. Limits on number of concurrent connections and requests to upstream services

1. Active and periodic health checks on each member of the [load balancing](../load-balancing)
   pool

1. Fine-grained [circuit breakers](#circuit), also known as passive health
   checks, applied per instance in the load balancing pool

These features can be dynamically configured at runtime through
[Istio's traffic management rules](../routing-rules).

The jitter between retries minimizes the impact of retries on an overloaded
upstream service, while timeout budgets ensure that the calling service
gets a response, either success or failure, within a predictable time frame.

A combination of active and passive health checks minimize the chances of
accessing an unhealthy instance in the load balancing pool. When combined with
platform-level health checks, such as those supported by Kubernetes or Mesos,
applications can quickly eject unhealthy pods, containers, or VMs  from the
service mesh, minimizing the request failures and impact on latency.

Together, these features enable the service mesh to tolerate failing nodes
and prevent localized failures from cascading instability to other nodes.

## Timeouts {#timeouts}

By default, the timeout for HTTP requests is 15 seconds, but you can override
the default with the following routing rule:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
    - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
    timeout: 10s
{{< /text >}}

> You can [override on a per-request basis](#fine-tuning) the length of the
> timeout.

Visit the [request timeouts task](/docs/tasks/traffic-management/request-timeouts)
for a thorough example of timeout control.

## Retries {#retries}

You can specify the number of retry attempts for an HTTP request in a virtual
service. You can set the maximum number of retry attempts, or the number of
attempts possible within the default or overridden timeout period as follows:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
    - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
    retries:
      attempts: 3
      perTryTimeout: 2s
{{< /text >}}

> You can [override on a per-request basis](#fine-tuning) the number of
> retries.

## Circuit breakers {#circuit}

You can set a simple circuit breaker based on a number of conditions such as
connection and request limits.

For example, the following destination rule
sets a limit of 100 connections to the `reviews` service `v1` subset workloads:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
    trafficPolicy:
      connectionPool:
        tcp:
          maxConnections: 100
{{< /text >}}

See the [circuit-breaking task](/docs/tasks/traffic-management/circuit-breaking/) for a demonstration of circuit breaker control.

## Fault injection {#fault-injection}

While the Envoy proxy provides a host of [failure recovery mechanisms](#handling-failures)
to services running on Istio, it is still imperative to test the end-to-end
failure recovery capability of the application as a whole. The wrong
configuration of the failure recovery policies, for example, incompatible or
restrictive timeouts across service calls, could result in continued
unavailability of critical services in the application, resulting in poor user
experience.

Istio enables protocol-specific fault injection into the network. Instead of
killing pods, delaying packets, or corrupting packets at the TCP layer. The
application layer observes the same failures regardless of the network layer
failures. You can inject more meaningful failures at the application layer, for
example, HTTP error codes, to exercise the resilience of an application.

You can configure Istio to inject faults into requests that match
specific conditions. You can further restrict the percentage of
requests Istio subjects to faults.

You can inject two types of faults:

* **Delays:** Delays are timing failures, mimicking increased network latency,
  or an overloaded upstream service.

* **Aborts:** Aborts are crash failures that mimic failures in upstream
  services. Aborts usually manifest in the form of HTTP error codes or TCP
  connection failures.

### Injecting faults

A virtual service can specify one or more faults to inject
while forwarding HTTP requests to the rule's corresponding request destination.
The faults can be either delays or aborts.

The following example introduces a 5 second delay in 10% of the requests to the
`v1` subset of the `ratings` service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      delay:
        percent: 10
        fixedDelay: 5s
    route:
    - destination:
        host: ratings
        subset: v1
{{< /text >}}

You can use the other kind of fault, an abort, to prematurely terminate a
request. For example, to simulate a failure.

The following example returns an `HTTP 400` error code for 10% of the requests
to the `v1` subset of the `ratings` service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      abort:
        percent: 10
        httpStatus: 400
    route:
    - destination:
        host: ratings
        subset: v1
{{< /text >}}

You can use delay and abort faults together. For example, the following rule
delays by 5 seconds all requests from the `v2` subset of the `ratings` service
to the `v1` subset of the `ratings` service and then aborts 10% of them:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - match:
    - sourceLabels:
        app: reviews
        version: v2
    fault:
      delay:
        fixedDelay: 5s
      abort:
        percent: 10
        httpStatus: 400
    route:
    - destination:
        host: ratings
        subset: v1
{{< /text >}}

To see fault injection in action, see the [fault injection task](/docs/tasks/traffic-management/fault-injection/).

## Fine tuning {#fine-tuning}

Istio's traffic management rules allow you to set defaults for failure recovery
per service and subset that apply to all callers. However, consumers of a
service can also override
[timeout](/docs/reference/config/istio.networking.v1alpha3/#HTTPRoute-timeout)
and
[retry](/docs/reference/config/istio.networking.v1alpha3/#HTTPRoute-retries)
defaults by providing request-level overrides through special HTTP headers.
With the Envoy proxy implementation, the headers are
`x-envoy-upstream-rq-timeout-ms` and `x-envoy-max-retries`, respectively.

## Failure handling FAQ {failure-handling}

**Q: Do applications still handle failures when running in Istio?**

Yes. Istio improves the reliability and availability of services in the mesh.
However, **applications need to handle the failure or errors and take
appropriate fallback actions**. For example, when all instances in a load
balancing pool have failed, Envoy returns an `HTTP 503` code. The application
must implement any fallback logic that is needed to handle the `HTTP 503` error
code from an upstream service.

**Q: Will Envoy's failure recovery features break applications that already
use fault tolerance libraries, for example, [Hystrix](https://github.com/Netflix/Hystrix))?**

No. Envoy is completely transparent to the application. Applications cannot
distinguish between Envoy's failure response and the failure response of the
called upstream service.

**Q: How does Istio handle failures when using application-level libraries and
Envoy at the same time?**

Given two failure recovery policies for the same destination service, **the
more restrictive of the two is triggered when failures occur**.  For example,
you have two timeouts: one set in Envoy and another in an application's
library. If the application sets a 5 second timeout for an API call to a
service and you configured a 10 second timeout in Envoy, the application's
timeout kicks in first. Similarly, if Envoy's circuit breaker triggers before
the application's circuit breaker, API calls to the service get an `HTTP 503`
error code from Envoy.

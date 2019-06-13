---
title: Network Resilience and Testing
description: Learn about the dynamic failure recovery features of Istio that you can configure to build tolerance for failing nodes, and to prevent cascading failures to other nodes.
weight: 3
keywords: [traffic-management, timeout, retry, circuit-breaker, health-check, fault-injection, fault-tolerance-library]
---

Istio provides opt-in failure recovery features that you can configure
dynamically at runtime through the [Istio traffic management rules](/docs/concepts/traffic-management/routing/virtual-services/#routing-rules).
With these features, the service mesh can tolerate failing nodes and Istio can
prevent localized failures from cascading to other nodes:

-  **Timeouts and retries**

    A timeout is the amount of time that Istio waits for a response to a
    request. A retry is an attempt to complete an operation multiple times if
    it fails. You can set defaults and specify request-level overrides for both
    timeouts and retries or for one or the other.

-  **Circuit breakers**

    Circuit breakers prevent your application from stalling as it waits for an
    upstream service to respond. You can configure a circuit breaker based on a
    number of conditions, such as connection and request limits.

-  **Health checks**

    A health check runs diagnostic tests on each member of a [load balancing](/docs/concepts/traffic-management/overview/#load-balancing)
    pool to help you troubleshoot connectivity issues.

-  **Fault injection**

    Fault injection is a testing method that introduces errors into a system to
    ensure that it can withstand and recover from error conditions. You can
    inject faults at the application layer, rather than the network layer, to
    get more relevant results.

-  **Fault tolerance**

    You can use Istio failure recovery features to complement application-level
    fault tolerance libraries in situations where their behaviors don’t
    conflict.

{{< warning >}}
While Istio failure recovery features improve the reliability and availability
of services in the mesh, applications must handle the failure or errors and
take appropriate fallback actions. For example, when all instances in a load
balancing pool have failed, Envoy returns an `HTTP 503` code. The application
must implement any fallback logic needed to handle the `HTTP 503` error code
from an upstream service.
{{< /warning >}}

## Timeouts and retries

You can use Istio's traffic management resources to set defaults for timeouts
and retries per service and subset that apply to all callers.

### Override default timeout setting

The default timeout for HTTP requests is 15 seconds. You can configure a
virtual service with a routing rule to override the default, for example:

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

### Set number and timeouts for retries

You can specify the maximum number of retries for an HTTP request in a virtual
service, and you can provide specific timeouts for the retries to ensure that
the calling service gets a response, either success or failure, within a
predictable time frame.

Envoy proxies automatically add variable jitter between your retries to
minimize the potential impact of retries on an overloaded upstream service.

The following virtual service configures three attempts with a 2-second
timeout:

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

Consumers of a service can also override timeout and retry defaults with
request-level overrides through special HTTP headers. The Envoy proxy
implementation makes the following headers available:

-  Timeouts: `x-envoy-upstream-rq-timeout-ms`

-  Retries: `X-envoy-max-retries`

## Circuit breakers

As with timeouts and retries, you can configure a circuit breaker pattern
without changing your services. While retries let your application recover from
transient errors, a circuit breaker pattern prevents your application from
stalling as it waits for an upstream service to respond. By configuring a
circuit breaker pattern, you allow your application to fail fast and handle the
error appropriately, for example, by triggering an alert. You can configure a
simple circuit breaker pattern based on a number of conditions such as
connection and request limits.

### Limit connections to 100

The following destination rule sets a limit of 100 connections for the
`reviews` service workloads of the v1 subset:

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

See the [circuit-breaking task](/docs/tasks/traffic-management/circuit-breaking/)
for detailed instructions on how to configure a circuit breaker pattern.

## Health checking

Istio currently supports passive health checking to minimize the chances of
accessing an unhealthy instance in the load balancing pool. The Envoy proxies
support active health checking but Istio doesn’t enable it. When you combine
Istio health checks with platform-level health checks, such as those supported
by Kubernetes, your applications can quickly eject unhealthy pods, containers,
or VMs from the service mesh, minimizing request failures and impact on
latency.

The Envoy proxies follow a circuit breaker pattern to classify instances as
unhealthy or healthy based on their failure rates for the health check API
call. The process to remove unhealthy instances from the load balancing pool is
independent of platform:

1. Envoy periodically checks the health of each instance in the load balancing
   pool.

1. When the number of failed health checks for a given instance exceeds a
   specified threshold, the Envoy proxy removes the instance from the service's
   load balancing pool.

1. When the number of passed health checks exceeds a specified threshold, the
   Envoy proxy adds the instance back into the service's load balancing pool.

Services can shed loads by returning a Service Unavailable (`HTTP 503`)
response to a health check. The Envoy proxy for the calling service immediately
removes the service instance from its load balancing pool.

## Fault injection

You can use fault injection to test the end-to-end failure recovery capability
of the application as a whole. An incorrect configuration of the failure
recovery policies could result in unavailability of critical services. Examples
of incorrect configurations include incompatible or restrictive timeouts across
service calls.

With Istio, you can use application-layer fault injection instead of killing
pods, delaying packets, or corrupting packets at the TCP layer. You can inject
more relevant failures at the application layer, such as HTTP error codes, to
test the resilience of an application.

You can inject faults into requests that match specific conditions, and you can
restrict the percentage of requests Istio subjects to faults.

You can inject two types of faults:

-  **Delays:** Delays are timing failures. They mimic increased network latency
   or an overloaded upstream service.

-  **Aborts:** Aborts are crash failures. They mimic failures in upstream
   services. Aborts usually manifest in the form of HTTP error codes or TCP
   connection failures.

You can configure a virtual service to inject one or more faults while
forwarding HTTP requests to the rule's corresponding request destination. The
faults can be either delays or aborts.

### Introduce a 5 second delay in 10% of requests

You can configure a virtual service to introduce a 5 second delay for 10% of
the requests to the `ratings` service.

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
        percentage:
  value: 0.1
        fixedDelay: 5s
    route:
    - destination:
        host: ratings
        subset: v1
{{< /text >}}

### Return an HTTP 400 error code for 10% of requests

You can configure an abort instead to terminate a request and simulate a
failure.

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
        percentage:
          value: 0.1
        httpStatus: 400
    route:
    - destination:
        host: ratings
        subset: v1
{{< /text >}}

### Combine delay and abort faults

You can use delay and abort faults together. The following configuration
introduces a delay of 5 seconds for all requests from the `v2` subset of the
`ratings` service to the `v1` subset of the `ratings` service and an abort for
10% of them:

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
        percentage:
          value: 0.1
        httpStatus: 400
    route:
    - destination:
        host: ratings
        subset: v1
{{< /text >}}

For detailed instructions on how to configure delays and aborts, visit our
[fault injection task](/docs/tasks/traffic-management/fault-injection/).

## Compatibility with fault tolerance libraries

Istio failure recovery features are completely transparent to the application.
Applications cannot distinguish between the Envoy proxy's failure response and
the failure response of the called upstream service, so fault tolerance
libraries such as [Hystrix](https://github.com/Netflix/Hystrix) are compatible
with Istio.

When you use application-level fault tolerance libraries and Envoy proxy
failure recovery policies at the same time, Istio first triggers the more
restrictive of the two when failures occur.

For example: Suppose you can have two timeouts, one configured in a virtual
service and another in an application's library. The application sets a
5 second timeout for an API call to a service. However, you configured a
10 second timeout in your virtual service. In this case, the application's
timeout kicks in first.

Similarly, if you configure a circuit breaker using Istio and it triggers
before the application's circuit breaker, the API calls to the service get an
HTTP `503` error code from Istio's Envoy proxy.



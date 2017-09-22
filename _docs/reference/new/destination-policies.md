---
title: Destination Policies
overview: Generated documentation for Istio's Configuration Schemas

order: 1000

layout: docs
type: markdown
---


<a name="rpcIstio.proxy.v1.configIndex"></a>
### Index

* [CircuitBreaker](#istio.proxy.v1.config.CircuitBreaker)
(message)
* [CircuitBreaker.SimpleCircuitBreakerPolicy](#istio.proxy.v1.config.CircuitBreaker.SimpleCircuitBreakerPolicy)
(message)
* [DestinationPolicy](#istio.proxy.v1.config.DestinationPolicy)
(message)
* [DestinationWeight](#istio.proxy.v1.config.DestinationWeight)
(message)
* [HTTPFaultInjection](#istio.proxy.v1.config.HTTPFaultInjection)
(message)
* [HTTPFaultInjection.Abort](#istio.proxy.v1.config.HTTPFaultInjection.Abort)
(message)
* [HTTPFaultInjection.Delay](#istio.proxy.v1.config.HTTPFaultInjection.Delay)
(message)
* [HTTPRedirect](#istio.proxy.v1.config.HTTPRedirect)
(message)
* [HTTPRetry](#istio.proxy.v1.config.HTTPRetry)
(message)
* [HTTPRetry.SimpleRetryPolicy](#istio.proxy.v1.config.HTTPRetry.SimpleRetryPolicy)
(message)
* [HTTPRewrite](#istio.proxy.v1.config.HTTPRewrite)
(message)
* [HTTPTimeout](#istio.proxy.v1.config.HTTPTimeout)
(message)
* [HTTPTimeout.SimpleTimeoutPolicy](#istio.proxy.v1.config.HTTPTimeout.SimpleTimeoutPolicy)
(message)
* [IstioService](#istio.proxy.v1.config.IstioService)
(message)
* [L4FaultInjection](#istio.proxy.v1.config.L4FaultInjection)
(message)
* [L4FaultInjection.Terminate](#istio.proxy.v1.config.L4FaultInjection.Terminate)
(message)
* [L4FaultInjection.Throttle](#istio.proxy.v1.config.L4FaultInjection.Throttle)
(message)
* [L4MatchAttributes](#istio.proxy.v1.config.L4MatchAttributes)
(message)
* [LoadBalancing](#istio.proxy.v1.config.LoadBalancing)
(message)
* [LoadBalancing.SimpleLBPolicy](#istio.proxy.v1.config.LoadBalancing.SimpleLBPolicy)
(enum)
* [MatchCondition](#istio.proxy.v1.config.MatchCondition)
(message)
* [MatchRequest](#istio.proxy.v1.config.MatchRequest)
(message)
* [RouteRule](#istio.proxy.v1.config.RouteRule)
(message)
* [StringMatch](#istio.proxy.v1.config.StringMatch)
(message)

<a name="istio.proxy.v1.config.CircuitBreaker"></a>
### CircuitBreaker
Circuit breaker configuration for Envoy. The circuit breaker
implementation is fine-grained in that it tracks the success/failure
rates of individual hosts in the load balancing pool. Hosts that
continually return errors for API calls are ejected from the pool for a
pre-defined period of time.
See Envoy's
[circuit breaker](https://envoyproxy.github.io/envoy/intro/archOverview/circuitBreaking.html)
and [outlier detection](https://envoyproxy.github.io/envoy/intro/archOverview/outlier.html)
for more details.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.CircuitBreaker.simpleCb"></a>
 <tr>
  <td><code>simpleCb</code></td>
  <td><a href="#istio.proxy.v1.config.CircuitBreaker.SimpleCircuitBreakerPolicy">SimpleCircuitBreakerPolicy</a></td>
  <td></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.CircuitBreaker.SimpleCircuitBreakerPolicy"></a>
### SimpleCircuitBreakerPolicy
A simple circuit breaker can be set based on a number of criteria such as
connection and request limits. For example, the following destination
policy sets a limit of 100 connections to "reviews" service version
"v1" backends. 


    metadata:
      name: reviews-cb-policy
      namespace: default
    spec:
      destination:
        name: reviews
        labels:
          version: v1
      circuitBreaker:
        simpleCb:
          maxConnections: 100


The following destination policy sets a limit of 100 connections and
1000 concurrent requests, with no more than 10 req/connection to
"reviews" service version "v1" backends. In addition, it configures
hosts to be scanned every 5 mins, such that any host that fails 7
consecutive times with 5XX error code will be ejected for 15 minutes.


    metadata:
      name: reviews-cb-policy
      namespace: default
    spec:
      destination:
        name: reviews
        labels:
          version: v1
      circuitBreaker:
        simpleCb:
          maxConnections: 100
          httpMaxRequests: 1000
          httpMaxRequestsPerConnection: 10
          httpConsecutiveErrors: 7
          sleepWindow: 15m
          httpDetectionInterval: 5m

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.CircuitBreaker.SimpleCircuitBreakerPolicy.maxConnections"></a>
 <tr>
  <td><code>maxConnections</code></td>
  <td>int32</td>
  <td>Maximum number of connections to a backend.</td>
 </tr>
<a name="istio.proxy.v1.config.CircuitBreaker.SimpleCircuitBreakerPolicy.httpMaxPendingRequests"></a>
 <tr>
  <td><code>httpMaxPendingRequests</code></td>
  <td>int32</td>
  <td>Maximum number of pending requests to a backend. Default 1024</td>
 </tr>
<a name="istio.proxy.v1.config.CircuitBreaker.SimpleCircuitBreakerPolicy.httpMaxRequests"></a>
 <tr>
  <td><code>httpMaxRequests</code></td>
  <td>int32</td>
  <td>Maximum number of requests to a backend. Default 1024</td>
 </tr>
<a name="istio.proxy.v1.config.CircuitBreaker.SimpleCircuitBreakerPolicy.sleepWindow"></a>
 <tr>
  <td><code>sleepWindow</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Minimum time the circuit will be closed. format: 1h/1m/1s/1ms. MUST BE &gt;=1ms. Default is 30s.</td>
 </tr>
<a name="istio.proxy.v1.config.CircuitBreaker.SimpleCircuitBreakerPolicy.httpConsecutiveErrors"></a>
 <tr>
  <td><code>httpConsecutiveErrors</code></td>
  <td>int32</td>
  <td>Number of 5XX errors before circuit is opened. Defaults to 5.</td>
 </tr>
<a name="istio.proxy.v1.config.CircuitBreaker.SimpleCircuitBreakerPolicy.httpDetectionInterval"></a>
 <tr>
  <td><code>httpDetectionInterval</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Time interval between ejection sweep analysis. format: 1h/1m/1s/1ms. MUST BE &gt;=1ms. Default is 10s.</td>
 </tr>
<a name="istio.proxy.v1.config.CircuitBreaker.SimpleCircuitBreakerPolicy.httpMaxRequestsPerConnection"></a>
 <tr>
  <td><code>httpMaxRequestsPerConnection</code></td>
  <td>int32</td>
  <td>Maximum number of requests per connection to a backend. Setting this parameter to 1 disables keep alive.</td>
 </tr>
<a name="istio.proxy.v1.config.CircuitBreaker.SimpleCircuitBreakerPolicy.httpMaxEjectionPercent"></a>
 <tr>
  <td><code>httpMaxEjectionPercent</code></td>
  <td>int32</td>
  <td>Maximum % of hosts in the load balancing pool for the destination service that can be ejected by the circuit breaker. Defaults to 10%.</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.DestinationPolicy"></a>
### DestinationPolicy
DestinationPolicy defines client/caller-side policies that determine how
to handle traffic bound to a particular destination service. The policy
specifies configuration for load balancing and circuit breakers. For
example, a simple load balancing policy for the ratings service would
look as follows:


    metadata:
      name: ratings-lb-policy
      namespace: default # optional (default is "default")
    spec:
      destination:
        name: ratings
      loadBalancing:
        name: ROUNDROBIN


The FQDN of the destination service is composed from the destination name and meta namespace fields, along with
a platform-specific domain suffix
(e.g. on Kubernetes, "reviews" + "default" + "svc.cluster.local" -> "reviews.default.svc.cluster.local").

A destination policy can be restricted to a particular version of a
service or applied to all versions. It can also be restricted to calls from
a particular source. For example, the following load balancing policy
applies to version v1 of the ratings service running in the prod
environment but only when called from version v2 of the reviews service:


    metadata:
      name: ratings-lb-policy
      namespace: default
    spec:
      source:
        name: reviews
        labels:
          version: v2
      destination:
        name: ratings
        labels:
          env: prod
          version: v1
      loadBalancing:
        name: ROUNDROBIN


*Note:* Destination policies will be applied only if the corresponding
tagged instances are explicity routed to. In other words, for every
destination policy defined, at least one route rule must refer to the
service version indicated in the destination policy.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.DestinationPolicy.destination"></a>
 <tr>
  <td><code>destination</code></td>
  <td><a href="#istio.proxy.v1.config.IstioService">IstioService</a></td>
  <td>Optional: Destination uniquely identifies the destination service associated with this policy.</td>
 </tr>
<a name="istio.proxy.v1.config.DestinationPolicy.source"></a>
 <tr>
  <td><code>source</code></td>
  <td><a href="#istio.proxy.v1.config.IstioService">IstioService</a></td>
  <td>Optional: Source uniquely identifies the source service associated with this policy.</td>
 </tr>
<a name="istio.proxy.v1.config.DestinationPolicy.loadBalancing"></a>
 <tr>
  <td><code>loadBalancing</code></td>
  <td><a href="#istio.proxy.v1.config.LoadBalancing">LoadBalancing</a></td>
  <td>Load balancing policy.</td>
 </tr>
<a name="istio.proxy.v1.config.DestinationPolicy.circuitBreaker"></a>
 <tr>
  <td><code>circuitBreaker</code></td>
  <td><a href="#istio.proxy.v1.config.CircuitBreaker">CircuitBreaker</a></td>
  <td>Circuit breaker policy.</td>
 </tr>
<a name="istio.proxy.v1.config.DestinationPolicy.custom"></a>
 <tr>
  <td><code>custom</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#any">Any</a></td>
  <td></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.DestinationWeight"></a>
### DestinationWeight
Each routing rule is associated with one or more service versions (see
glossary in beginning of document). Weights associated with the version
determine the proportion of traffic it receives. For example, the
following rule will route 25% of traffic for the "reviews" service to
instances with the "v2" tag and the remaining traffic (i.e., 75%) to
"v1".


    metadata:
      name: my-rule
      namespace: default
    spec:
      destination:
        name: reviews
      route:
      - labels:
          version: v2
        weight: 25
      - labels:
          version: v1
        weight: 75

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.DestinationWeight.destination"></a>
 <tr>
  <td><code>destination</code></td>
  <td><a href="#istio.proxy.v1.config.IstioService">IstioService</a></td>
  <td>Optional destination uniquely identifies the destination service. If not specified, the value is inherited from the parent route rule.</td>
 </tr>
<a name="istio.proxy.v1.config.DestinationWeight.labels"></a>
 <tr>
  <td><code>labels</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td>Service version identifier for the destination service.</td>
 </tr>
<a name="istio.proxy.v1.config.DestinationWeight.weight"></a>
 <tr>
  <td><code>weight</code></td>
  <td>int32</td>
  <td>REQUIRED. The proportion of traffic to be forwarded to the service version. (0-100). Sum of weights across destinations SHOULD BE == 100. If there is only destination in a rule, the weight value is assumed to be 100.</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.HTTPFaultInjection"></a>
### HTTPFaultInjection
HTTPFaultInjection can be used to specify one or more faults to inject
while forwarding http requests to the destination specified in the route
rule.  Fault specification is part of a route rule. Faults include
aborting the Http request from downstream service, and/or delaying
proxying of requests. A fault rule MUST HAVE delay or abort or both.

*Note:* Delay and abort faults are independent of one another, even if
both are specified simultaneously.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.HTTPFaultInjection.delay"></a>
 <tr>
  <td><code>delay</code></td>
  <td><a href="#istio.proxy.v1.config.HTTPFaultInjection.Delay">Delay</a></td>
  <td>Delay requests before forwarding, emulating various failures such as network issues, overloaded upstream service, etc.</td>
 </tr>
<a name="istio.proxy.v1.config.HTTPFaultInjection.abort"></a>
 <tr>
  <td><code>abort</code></td>
  <td><a href="#istio.proxy.v1.config.HTTPFaultInjection.Abort">Abort</a></td>
  <td>Abort Http request attempts and return error codes back to downstream service, giving the impression that the upstream service is faulty.</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.HTTPFaultInjection.Abort"></a>
### Abort
Abort specification is used to prematurely abort a request with a
pre-specified error code. The following example will return an HTTP
400 error code for 10% of the requests to the "ratings" service "v1".


    metadata:
      name: my-rule
    spec:
      destination:
        name: reviews
      route:
      - labels:
          version: v1
      httpFault:
        abort:
          percent: 10
          httpStatus: 400


The HttpStatus_ field is used to indicate the HTTP status code to
return to the caller. The optional Percent_ field, a value between 0
and 100, is used to only abort a certain percentage of requests. If
not specified, all requests are aborted.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.HTTPFaultInjection.Abort.percent"></a>
 <tr>
  <td><code>percent</code></td>
  <td>float</td>
  <td>percentage of requests to be aborted with the error code provided (0-100).</td>
 </tr>
<a name="istio.proxy.v1.config.HTTPFaultInjection.Abort.overrideHeaderName"></a>
 <tr>
  <td><code>overrideHeaderName</code></td>
  <td>string</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1.config.HTTPFaultInjection.Abort.grpcStatus"></a>
 <tr>
  <td><code>grpcStatus</code></td>
  <td>string (oneof )</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1.config.HTTPFaultInjection.Abort.http2Error"></a>
 <tr>
  <td><code>http2Error</code></td>
  <td>string (oneof )</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1.config.HTTPFaultInjection.Abort.httpStatus"></a>
 <tr>
  <td><code>httpStatus</code></td>
  <td>int32 (oneof )</td>
  <td>REQUIRED. HTTP status code to use to abort the Http request.</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.HTTPFaultInjection.Delay"></a>
### Delay
Delay specification is used to inject latency into the request
forwarding path. The following example will introduce a 5 second delay
in 10% of the requests to the "v1" version of the "reviews"
service.


    metadata:
      name: my-rule
    spec:
      destination:
        name: reviews
      route:
      - labels:
          version: v1
      httpFault:
        delay:
          percent: 10
          fixedDelay: 5s


The FixedDelay_ field is used to indicate the amount of delay in
seconds. An optional Percent_ field, a value between 0 and 100, can
be used to only delay a certain percentage of requests. If left
unspecified, all request will be delayed.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.HTTPFaultInjection.Delay.percent"></a>
 <tr>
  <td><code>percent</code></td>
  <td>float</td>
  <td>percentage of requests on which the delay will be injected (0-100)</td>
 </tr>
<a name="istio.proxy.v1.config.HTTPFaultInjection.Delay.overrideHeaderName"></a>
 <tr>
  <td><code>overrideHeaderName</code></td>
  <td>string</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1.config.HTTPFaultInjection.Delay.fixedDelay"></a>
 <tr>
  <td><code>fixedDelay</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a> (oneof )</td>
  <td>REQUIRED. Add a fixed delay before forwarding the request. Format: 1h/1m/1s/1ms. MUST be &gt;=1ms.</td>
 </tr>
<a name="istio.proxy.v1.config.HTTPFaultInjection.Delay.exponentialDelay"></a>
 <tr>
  <td><code>exponentialDelay</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a> (oneof )</td>
  <td></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.HTTPRedirect"></a>
### HTTPRedirect
HTTPRedirect can be used to send a 302 redirect response to the caller,
where the Authority/Host and the URI in the response can be swapped with
the specified values. For example, the following route rule redirects
requests for /v1/getProductRatings API on the ratings service to
/v1/bookRatings provided by the bookratings service.


    metadata:
      name: my-rule
      namespace: default
    spec:
      destination:
        name: ratings
      match:
        request:
          headers:
            uri: /v1/getProductRatings
      redirect:
        uri: /v1/bookRatings
        authority: bookratings.default.svc.cluster.local

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.HTTPRedirect.uri"></a>
 <tr>
  <td><code>uri</code></td>
  <td>string</td>
  <td>On a redirect, overwrite the Path portion of the URL with this value. Note that the entire path will be replaced, irrespective of the request URI being matched as an exact path or prefix.</td>
 </tr>
<a name="istio.proxy.v1.config.HTTPRedirect.authority"></a>
 <tr>
  <td><code>authority</code></td>
  <td>string</td>
  <td>On a redirect, overwrite the Authority/Host portion of the URL with this value</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.HTTPRetry"></a>
### HTTPRetry
Describes the retry policy to use when a HTTP request fails. For
example, the following rule sets the maximum number of retries to 3 when
calling ratings:v1 service, with a 2s timeout per retry attempt.


    metadata:
      name: my-rule
      namespace: default
    spec:
      destination:
        name: ratings
      route:
      - labels:
          version: v1
      httpReqRetries:
        simpleRetry:
          attempts: 3
          perTryTimeout: 2s

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.HTTPRetry.simpleRetry"></a>
 <tr>
  <td><code>simpleRetry</code></td>
  <td><a href="#istio.proxy.v1.config.HTTPRetry.SimpleRetryPolicy">SimpleRetryPolicy</a> (oneof )</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1.config.HTTPRetry.custom"></a>
 <tr>
  <td><code>custom</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#any">Any</a> (oneof )</td>
  <td></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.HTTPRetry.SimpleRetryPolicy"></a>
### SimpleRetryPolicy

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.HTTPRetry.SimpleRetryPolicy.attempts"></a>
 <tr>
  <td><code>attempts</code></td>
  <td>int32</td>
  <td>REQUIRED. Number of retries for a given request. The interval between retries will be determined automatically (25ms+). Actual number of retries attempted depends on the httpReqTimeout.</td>
 </tr>
<a name="istio.proxy.v1.config.HTTPRetry.SimpleRetryPolicy.perTryTimeout"></a>
 <tr>
  <td><code>perTryTimeout</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Timeout per retry attempt for a given request. format: 1h/1m/1s/1ms. MUST BE &gt;=1ms.</td>
 </tr>
<a name="istio.proxy.v1.config.HTTPRetry.SimpleRetryPolicy.overrideHeaderName"></a>
 <tr>
  <td><code>overrideHeaderName</code></td>
  <td>string</td>
  <td></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.HTTPRewrite"></a>
### HTTPRewrite
HTTPRewrite can be used to rewrite specific parts of a HTTP request
before forwarding the request to the destination. Rewrite primitive can
be used only with the DestinationWeights. The following example
demonstrates how to rewrite the URL prefix for api call (/ratings) to
ratings service before making the actual API call.


    metadata:
      name: my-rule
      namespace: default
    spec:
      destination:
        name: ratings
      match:
        request:
          headers:
            uri:
              prefix: /ratings
      rewrite:
        uri: /v1/bookRatings
      route:
      - labels:
          version: v1

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.HTTPRewrite.uri"></a>
 <tr>
  <td><code>uri</code></td>
  <td>string</td>
  <td>rewrite the Path (or the prefix) portion of the URI with this value. If the original URI was matched based on prefix, the value provided in this field will replace the corresponding matched prefix.</td>
 </tr>
<a name="istio.proxy.v1.config.HTTPRewrite.authority"></a>
 <tr>
  <td><code>authority</code></td>
  <td>string</td>
  <td>rewrite the Authority/Host header with this value.</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.HTTPTimeout"></a>
### HTTPTimeout
Describes HTTP request timeout. For example, the following rule sets a
10 second timeout for calls to the ratings:v1 service


    metadata:
      name: my-rule
      namespace: default
    spec:
      destination:
        name: ratings
      route:
      - labels:
          version: v1
      httpReqTimeout:
        simpleTimeout:
          timeout: 10s

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.HTTPTimeout.simpleTimeout"></a>
 <tr>
  <td><code>simpleTimeout</code></td>
  <td><a href="#istio.proxy.v1.config.HTTPTimeout.SimpleTimeoutPolicy">SimpleTimeoutPolicy</a> (oneof )</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1.config.HTTPTimeout.custom"></a>
 <tr>
  <td><code>custom</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#any">Any</a> (oneof )</td>
  <td></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.HTTPTimeout.SimpleTimeoutPolicy"></a>
### SimpleTimeoutPolicy

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.HTTPTimeout.SimpleTimeoutPolicy.timeout"></a>
 <tr>
  <td><code>timeout</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>REQUIRED. Timeout for a HTTP request. Includes retries as well. Default 15s. format: 1h/1m/1s/1ms. MUST BE &gt;=1ms. It is possible to control timeout per request by supplying the timeout value via x-envoy-upstream-rq-timeout-ms HTTP header.</td>
 </tr>
<a name="istio.proxy.v1.config.HTTPTimeout.SimpleTimeoutPolicy.overrideHeaderName"></a>
 <tr>
  <td><code>overrideHeaderName</code></td>
  <td>string</td>
  <td></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.IstioService"></a>
### IstioService
IstioService identifies a service and optionally service version.
The FQDN of the service is composed from the name, namespace, and implementation-specific domain suffix
(e.g. on Kubernetes, "reviews" + "default" + "svc.cluster.local" -> "reviews.default.svc.cluster.local").

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.IstioService.name"></a>
 <tr>
  <td><code>name</code></td>
  <td>string</td>
  <td>The short name of the service such as "foo".</td>
 </tr>
<a name="istio.proxy.v1.config.IstioService.namespace"></a>
 <tr>
  <td><code>namespace</code></td>
  <td>string</td>
  <td>Optional namespace of the service. Defaults to value of metadata namespace field.</td>
 </tr>
<a name="istio.proxy.v1.config.IstioService.domain"></a>
 <tr>
  <td><code>domain</code></td>
  <td>string</td>
  <td>Domain suffix used to construct the service FQDN in implementations that support such specification.</td>
 </tr>
<a name="istio.proxy.v1.config.IstioService.service"></a>
 <tr>
  <td><code>service</code></td>
  <td>string</td>
  <td>The service FQDN.</td>
 </tr>
<a name="istio.proxy.v1.config.IstioService.labels"></a>
 <tr>
  <td><code>labels</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td><p>Optional one or more labels that uniquely identify the service version.</p><p><em>Note:</em> When used for a RouteRule destination, labels MUST be empty.</p></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.L4FaultInjection"></a>
### L4FaultInjection

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.L4FaultInjection.throttle"></a>
 <tr>
  <td><code>throttle</code></td>
  <td><a href="#istio.proxy.v1.config.L4FaultInjection.Throttle">Throttle</a></td>
  <td>Unlike Http services, we have very little context for raw Tcp|Udp connections. We could throttle bandwidth of the connections (slow down the connection) and/or abruptly reset (terminate) the Tcp connection after it has been established. We first throttle (if set) and then terminate the connection.</td>
 </tr>
<a name="istio.proxy.v1.config.L4FaultInjection.terminate"></a>
 <tr>
  <td><code>terminate</code></td>
  <td><a href="#istio.proxy.v1.config.L4FaultInjection.Terminate">Terminate</a></td>
  <td></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.L4FaultInjection.Terminate"></a>
### Terminate
Abruptly reset (terminate) the Tcp connection after it has been
established, emulating remote server crash or link failure.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.L4FaultInjection.Terminate.percent"></a>
 <tr>
  <td><code>percent</code></td>
  <td>float</td>
  <td>percentage of established Tcp connections to be terminated/reset</td>
 </tr>
<a name="istio.proxy.v1.config.L4FaultInjection.Terminate.terminateAfterPeriod"></a>
 <tr>
  <td><code>terminateAfterPeriod</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.L4FaultInjection.Throttle"></a>
### Throttle
Bandwidth throttling for Tcp and Udp connections

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.L4FaultInjection.Throttle.percent"></a>
 <tr>
  <td><code>percent</code></td>
  <td>float</td>
  <td>percentage of connections to throttle.</td>
 </tr>
<a name="istio.proxy.v1.config.L4FaultInjection.Throttle.downstreamLimitBps"></a>
 <tr>
  <td><code>downstreamLimitBps</code></td>
  <td>int64</td>
  <td>bandwidth limit in "bits" per second between downstream and Envoy</td>
 </tr>
<a name="istio.proxy.v1.config.L4FaultInjection.Throttle.upstreamLimitBps"></a>
 <tr>
  <td><code>upstreamLimitBps</code></td>
  <td>int64</td>
  <td>bandwidth limits in "bits" per second between Envoy and upstream</td>
 </tr>
<a name="istio.proxy.v1.config.L4FaultInjection.Throttle.throttleForPeriod"></a>
 <tr>
  <td><code>throttleForPeriod</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Stop throttling after the given duration. If not set, the connection will be throttled for its lifetime.</td>
 </tr>
<a name="istio.proxy.v1.config.L4FaultInjection.Throttle.throttleAfterPeriod"></a>
 <tr>
  <td><code>throttleAfterPeriod</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a> (oneof )</td>
  <td>Wait a while after the connection is established, before starting bandwidth throttling. This would allow us to inject fault after the application protocol (e.g., MySQL) has had time to establish sessions/whatever handshake necessary.</td>
 </tr>
<a name="istio.proxy.v1.config.L4FaultInjection.Throttle.throttleAfterBytes"></a>
 <tr>
  <td><code>throttleAfterBytes</code></td>
  <td>double (oneof )</td>
  <td>Alternatively, we could wait for a certain number of bytes to be transferred to upstream before throttling the bandwidth.</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.L4MatchAttributes"></a>
### L4MatchAttributes

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.L4MatchAttributes.sourceSubnet"></a>
 <tr>
  <td><code>sourceSubnet[]</code></td>
  <td>repeated string</td>
  <td>IPv4 or IPv6 ip address with optional subnet. E.g., a.b.c.d/xx form or just a.b.c.d</td>
 </tr>
<a name="istio.proxy.v1.config.L4MatchAttributes.destinationSubnet"></a>
 <tr>
  <td><code>destinationSubnet[]</code></td>
  <td>repeated string</td>
  <td>IPv4 or IPv6 ip address of destination with optional subnet. E.g., a.b.c.d/xx form or just a.b.c.d. This is only valid when the destination service has several IPs and the application explicitly specifies a particular IP.</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.LoadBalancing"></a>
### LoadBalancing
Load balancing policy to use when forwarding traffic. These policies
directly correlate to [load balancer
types](https://envoyproxy.github.io/envoy/intro/archOverview/loadBalancing.html)
supported by Envoy. Example,


    metadata:
      name: reviews-lb-policy
      namespace: default
    spec:
      destination:
        name: reviews
      loadBalancing:
        name: RANDOM

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.LoadBalancing.name"></a>
 <tr>
  <td><code>name</code></td>
  <td><a href="#istio.proxy.v1.config.LoadBalancing.SimpleLBPolicy">SimpleLBPolicy</a></td>
  <td>Load balancing policy name (as defined in SimpleLBPolicy below)</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.LoadBalancing.SimpleLBPolicy"></a>
### SimpleLBPolicy
Load balancing algorithms supported by Envoy proxy.


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.LoadBalancing.SimpleLBPolicy.ROUNDROBIN"></a>
 <tr>
  <td>ROUNDROBIN</td>
  <td>Simple round robin policy.</td>
 </tr>
<a name="istio.proxy.v1.config.LoadBalancing.SimpleLBPolicy.LEASTCONN"></a>
 <tr>
  <td>LEASTCONN</td>
  <td>The least request load balancer uses an O(1) algorithm which selects two random healthy hosts and picks the host which has fewer active requests.</td>
 </tr>
<a name="istio.proxy.v1.config.LoadBalancing.SimpleLBPolicy.RANDOM"></a>
 <tr>
  <td>RANDOM</td>
  <td>The random load balancer selects a random healthy host. The random load balancer generally performs better than round robin if no health checking policy is configured.</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.MatchCondition"></a>
### MatchCondition
Match condition specifies a set of criterion to be met in order for the
route rule to be applied to the connection or HTTP request. The
condition provides distinct set of conditions for each protocol with the
intention that conditions apply only to the service ports that match the
protocol. For example, the following route rule restricts the rule to
match only requests originating from "reviews:v2", accessing ratings
service where the URL path starts with /ratings/v2/ and the request
contains a "cookie" with value "user=jason",


    metadata:
      name: my-rule
      namespace: default
    spec:
      destination:
        name: ratings
      match:
        source:
          name: reviews
          labels:
            version: v2
        request:
          headers:
            cookie:
              regex: "^(.*?;)?(user=jason)(;.*)?"
            uri:
              prefix: "/ratings/v2/"


MatchCondition CANNOT be empty. At least one source or
request header must be specified.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.MatchCondition.source"></a>
 <tr>
  <td><code>source</code></td>
  <td><a href="#istio.proxy.v1.config.IstioService">IstioService</a></td>
  <td>Identifies the service initiating a connection or a request.</td>
 </tr>
<a name="istio.proxy.v1.config.MatchCondition.tcp"></a>
 <tr>
  <td><code>tcp</code></td>
  <td><a href="#istio.proxy.v1.config.L4MatchAttributes">L4MatchAttributes</a></td>
  <td></td>
 </tr>
<a name="istio.proxy.v1.config.MatchCondition.udp"></a>
 <tr>
  <td><code>udp</code></td>
  <td><a href="#istio.proxy.v1.config.L4MatchAttributes">L4MatchAttributes</a></td>
  <td></td>
 </tr>
<a name="istio.proxy.v1.config.MatchCondition.request"></a>
 <tr>
  <td><code>request</code></td>
  <td><a href="#istio.proxy.v1.config.MatchRequest">MatchRequest</a></td>
  <td>Attributes of an HTTP request to match.</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.MatchRequest"></a>
### MatchRequest
MatchRequest specifies the attributes of an HTTP request to be used for matching a request.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.MatchRequest.headers"></a>
 <tr>
  <td><code>headers</code></td>
  <td>repeated map&lt;string, <a href="#istio.proxy.v1.config.StringMatch">StringMatch</a>&gt;</td>
  <td><p>Set of HTTP match conditions based on HTTP/1.1, HTTP/2, GRPC request metadata, such as <em>uri</em>, <em>scheme</em>, <em>authority</em>. The header keys must be lowercase and use hyphen as the separator, e.g. <em>x-request-id</em>.</p><p>Header values are case-sensitive and formatted as follows:</p><p><em>exact: "value"</em> or just <em>"value"</em> for exact string match</p><p><em>prefix: "value"</em> for prefix-based match</p><p><em>regex: "value"</em> for ECMAscript style regex-based match</p><p><em>Note 1:</em> The keys <em>uri</em>, <em>scheme</em>, <em>method</em>, and <em>authority</em> correspond to URI, protocol scheme (e.g., HTTP, HTTPS), HTTP method (e.g., GET, POST), and the HTTP Host header respectively.</p><p><em>Note 2:</em> <em>uri</em> can be used to perform URL matches. For all HTTP headers including <em>uri</em>, exact, prefix and ECMA style regular expression matches are supported.</p></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.RouteRule"></a>
### RouteRule

<a name="rpcIstio.proxy.v1.configIstio.proxy.v1.config.RouteRuleDescriptionSubsectionSubsectionSubsection"></a>
#### Glossary & concepts
*Service* is a unit of an application with a unique name that other services
use to refer to the functionality being called. Service instances are
pods/VMs/containers that implement the service.

*Service versions* - In a continuous deployment scenario, for a given service,
there can be multiple sets of instances running potentially different
variants of the application binary. These variants are not necessarily
different API versions. They could be iterative changes to the same service,
deployed in different environments (prod, staging, dev, etc.). Common
scenarios where this occurs include A/B testing, canary rollouts, etc. The
choice of a particular version can be decided based on various criterion
(headers, url, etc.) and/or by weights assigned to each version.  Each
service has a default version consisting of all its instances.

*Source* - downstream client (browser or another service) calling the
Envoy proxy/sidecar (typically to reach another service).

*Destination* - The remote upstream service to which the Envoy proxy/sidecar is
talking to, on behalf of the source service. There can be one or more
service versions for a given service (see the discussion on versions above).
Envoy would choose the version based on various routing rules.

*Access model* - Applications address only the destination service
without knowledge of individual service versions. The actual choice of
the version is determined by Envoy, enabling the application code to
decouple itself from the evolution of dependent services.



Route rule provides a custom routing policy based on the source and
destination service versions and connection/request metadata.  The rule
must provide a set of conditions for each protocol (TCP, UDP, HTTP) that
the destination service exposes on its ports.

The rule applies only to the ports on the destination service for which
it provides protocol-specific match condition, e.g. if the rule does not
specify TCP condition, the rule does not apply to TCP traffic towards
the destination service.

For example, a simple rule to send 100% of incoming traffic for a
"reviews" service to version "v1" can be specified as follows:


    metadata:
      name: my-rule
      namespace: default # optional (default is "default")
    spec:
      destination:
        name: reviews
        namespace: my-namespace # optional (default is metadata namespace field)
      route:
      - labels:
          version: v1
        weight: 100

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.RouteRule.destination"></a>
 <tr>
  <td><code>destination</code></td>
  <td><a href="#istio.proxy.v1.config.IstioService">IstioService</a></td>
  <td><p>REQUIRED: Destination uniquely identifies the destination associated with this routing rule. This field is applicable for hostname-based resolution for HTTP traffic as well as IP-based resolution for TCP/UDP traffic.</p><p><em>Note:</em> The route rule destination specification represents all version of the service and therefore the IstioService's labels field MUST be empty.</p></td>
 </tr>
<a name="istio.proxy.v1.config.RouteRule.precedence"></a>
 <tr>
  <td><code>precedence</code></td>
  <td>int32</td>
  <td>RECOMMENDED. Precedence is used to disambiguate the order of application of rules for the same destination service. A higher number takes priority. If not specified, the value is assumed to be 0. The order of application for rules with the same precedence is unspecified.</td>
 </tr>
<a name="istio.proxy.v1.config.RouteRule.match"></a>
 <tr>
  <td><code>match</code></td>
  <td><a href="#istio.proxy.v1.config.MatchCondition">MatchCondition</a></td>
  <td>Match condtions to be satisfied for the route rule to be activated. If match is omitted, the route rule applies only to HTTP traffic.</td>
 </tr>
<a name="istio.proxy.v1.config.RouteRule.route"></a>
 <tr>
  <td><code>route[]</code></td>
  <td>repeated <a href="#istio.proxy.v1.config.DestinationWeight">DestinationWeight</a></td>
  <td>REQUIRED (route|redirect). A routing rule can either redirect traffic or forward traffic. The forwarding target can be one of several versions of a service (see glossary in beginning of document). Weights associated with the service version determine the proportion of traffic it receives.</td>
 </tr>
<a name="istio.proxy.v1.config.RouteRule.redirect"></a>
 <tr>
  <td><code>redirect</code></td>
  <td><a href="#istio.proxy.v1.config.HTTPRedirect">HTTPRedirect</a></td>
  <td>REQUIRED (route|redirect). A routing rule can either redirect traffic or forward traffic. The redirect primitive can be used to send a HTTP 302 redirect to a different URI or Authority.</td>
 </tr>
<a name="istio.proxy.v1.config.RouteRule.rewrite"></a>
 <tr>
  <td><code>rewrite</code></td>
  <td><a href="#istio.proxy.v1.config.HTTPRewrite">HTTPRewrite</a></td>
  <td>Rewrite HTTP URIs and Authority headers. Rewrite cannot be used with Redirect primitive. Rewrite will be performed before forwarding.</td>
 </tr>
<a name="istio.proxy.v1.config.RouteRule.websocketUpgrade"></a>
 <tr>
  <td><code>websocketUpgrade</code></td>
  <td>bool</td>
  <td>Indicates that a HTTP/1.1 client connection to this particular route should be allowed (and expected) to upgrade to a WebSocket connection. The default is false. Envoy expects the first request to this route to contain the WebSocket upgrade headers. Otherwise, the request will be rejected.</td>
 </tr>
<a name="istio.proxy.v1.config.RouteRule.httpReqTimeout"></a>
 <tr>
  <td><code>httpReqTimeout</code></td>
  <td><a href="#istio.proxy.v1.config.HTTPTimeout">HTTPTimeout</a></td>
  <td>Timeout policy for HTTP requests.</td>
 </tr>
<a name="istio.proxy.v1.config.RouteRule.httpReqRetries"></a>
 <tr>
  <td><code>httpReqRetries</code></td>
  <td><a href="#istio.proxy.v1.config.HTTPRetry">HTTPRetry</a></td>
  <td>Retry policy for HTTP requests.</td>
 </tr>
<a name="istio.proxy.v1.config.RouteRule.httpFault"></a>
 <tr>
  <td><code>httpFault</code></td>
  <td><a href="#istio.proxy.v1.config.HTTPFaultInjection">HTTPFaultInjection</a></td>
  <td>Fault injection policy to apply on HTTP traffic</td>
 </tr>
<a name="istio.proxy.v1.config.RouteRule.l4Fault"></a>
 <tr>
  <td><code>l4Fault</code></td>
  <td><a href="#istio.proxy.v1.config.L4FaultInjection">L4FaultInjection</a></td>
  <td></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.StringMatch"></a>
### StringMatch
Describes how to match a given string in HTTP headers. Match is case-sensitive.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.StringMatch.exact"></a>
 <tr>
  <td><code>exact</code></td>
  <td>string (oneof )</td>
  <td>exact string match</td>
 </tr>
<a name="istio.proxy.v1.config.StringMatch.prefix"></a>
 <tr>
  <td><code>prefix</code></td>
  <td>string (oneof )</td>
  <td>prefix-based match</td>
 </tr>
<a name="istio.proxy.v1.config.StringMatch.regex"></a>
 <tr>
  <td><code>regex</code></td>
  <td>string (oneof )</td>
  <td>ECMAscript style regex-based match</td>
 </tr>
</table>

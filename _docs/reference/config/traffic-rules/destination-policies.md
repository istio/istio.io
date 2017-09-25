---
title: Destination Policies
overview: Client-side traffic management policies configuration schema

order: 30

layout: docs
type: markdown
---

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
        name: ROUND_ROBIN


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
        name: ROUND_ROBIN


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
  <td><a href="/docs/reference/config/traffic-rules/routing-rules.html#istio.proxy.v1.config.IstioService">IstioService</a></td>
  <td>Optional: Destination uniquely identifies the destination service associated with this policy.</td>
 </tr>
<a name="istio.proxy.v1.config.DestinationPolicy.source"></a>
 <tr>
  <td><code>source</code></td>
  <td><a href="/docs/reference/config/traffic-rules/routing-rules.html#istio.proxy.v1.config.IstioService">IstioService</a></td>
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

<a name="istio.proxy.v1.config.LoadBalancing"></a>
### LoadBalancing
Load balancing policy to use when forwarding traffic. These policies
directly correlate to [load balancer
types](https://envoyproxy.github.io/envoy/intro/arch_overview/load_balancing.html)
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
#### SimpleLBPolicy
Load balancing algorithms supported by Envoy proxy.


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.LoadBalancing.SimpleLBPolicy.ROUND_ROBIN"></a>
 <tr>
  <td>ROUND_ROBIN</td>
  <td>Simple round robin policy.</td>
 </tr>
<a name="istio.proxy.v1.config.LoadBalancing.SimpleLBPolicy.LEAST_CONN"></a>
 <tr>
  <td>LEAST_CONN</td>
  <td>The least request load balancer uses an O(1) algorithm which selects two random healthy hosts and picks the host which has fewer active requests.</td>
 </tr>
<a name="istio.proxy.v1.config.LoadBalancing.SimpleLBPolicy.RANDOM"></a>
 <tr>
  <td>RANDOM</td>
  <td>The random load balancer selects a random healthy host. The random load balancer generally performs better than round robin if no health checking policy is configured.</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.CircuitBreaker"></a>
### CircuitBreaker
Circuit breaker configuration for Envoy. The circuit breaker
implementation is fine-grained in that it tracks the success/failure
rates of individual hosts in the load balancing pool. Hosts that
continually return errors for API calls are ejected from the pool for a
pre-defined period of time.
See Envoy's
[circuit breaker](https://envoyproxy.github.io/envoy/intro/arch_overview/circuit_breaking.html)
and [outlier detection](https://envoyproxy.github.io/envoy/intro/arch_overview/outlier.html)
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
#### SimpleCircuitBreakerPolicy
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

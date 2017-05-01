---
title: Proxy Configuration Schema
overview: Generated documentation for the Istio Proxy's Configuration Schema
              
order: 60

layout: docs
type: markdown
---
<a name="rpc_istio.proxy.v1alpha.config"></a>
## Package istio.proxy.v1alpha.config

<a name="rpc_istio.proxy.v1alpha.config_index"></a>
### Index

* [CircuitBreaker](#istio.proxy.v1alpha.config.CircuitBreaker)
(message)
* [CircuitBreaker.SimpleCircuitBreakerPolicy](#istio.proxy.v1alpha.config.CircuitBreaker.SimpleCircuitBreakerPolicy)
(message)
* [DestinationPolicy](#istio.proxy.v1alpha.config.DestinationPolicy)
(message)
* [DestinationWeight](#istio.proxy.v1alpha.config.DestinationWeight)
(message)
* [HTTPFaultInjection](#istio.proxy.v1alpha.config.HTTPFaultInjection)
(message)
* [HTTPFaultInjection.Abort](#istio.proxy.v1alpha.config.HTTPFaultInjection.Abort)
(message)
* [HTTPFaultInjection.Delay](#istio.proxy.v1alpha.config.HTTPFaultInjection.Delay)
(message)
* [HTTPRetry](#istio.proxy.v1alpha.config.HTTPRetry)
(message)
* [HTTPRetry.SimpleRetryPolicy](#istio.proxy.v1alpha.config.HTTPRetry.SimpleRetryPolicy)
(message)
* [HTTPTimeout](#istio.proxy.v1alpha.config.HTTPTimeout)
(message)
* [HTTPTimeout.SimpleTimeoutPolicy](#istio.proxy.v1alpha.config.HTTPTimeout.SimpleTimeoutPolicy)
(message)
* [L4FaultInjection](#istio.proxy.v1alpha.config.L4FaultInjection)
(message)
* [L4FaultInjection.Terminate](#istio.proxy.v1alpha.config.L4FaultInjection.Terminate)
(message)
* [L4FaultInjection.Throttle](#istio.proxy.v1alpha.config.L4FaultInjection.Throttle)
(message)
* [L4MatchAttributes](#istio.proxy.v1alpha.config.L4MatchAttributes)
(message)
* [LoadBalancing](#istio.proxy.v1alpha.config.LoadBalancing)
(message)
* [LoadBalancing.SimpleLBPolicy](#istio.proxy.v1alpha.config.LoadBalancing.SimpleLBPolicy)
(enum)
* [MatchCondition](#istio.proxy.v1alpha.config.MatchCondition)
(message)
* [ProxyMeshConfig](#istio.proxy.v1alpha.config.ProxyMeshConfig)
(message)
* [ProxyMeshConfig.AuthPolicy](#istio.proxy.v1alpha.config.ProxyMeshConfig.AuthPolicy)
(enum)
* [ProxyMeshConfig.IngressControllerMode](#istio.proxy.v1alpha.config.ProxyMeshConfig.IngressControllerMode)
(enum)
* [RouteRule](#istio.proxy.v1alpha.config.RouteRule)
(message)
* [StringMatch](#istio.proxy.v1alpha.config.StringMatch)
(message)

<a name="istio.proxy.v1alpha.config.CircuitBreaker"></a>
### CircuitBreaker
Circuit breaker configuration.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.CircuitBreaker.simple_cb"></a>
 <tr>
  <td><code>simple_cb</code></td>
  <td><a href="#istio.proxy.v1alpha.config.CircuitBreaker.SimpleCircuitBreakerPolicy">SimpleCircuitBreakerPolicy</a> (oneof )</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1alpha.config.CircuitBreaker.custom"></a>
 <tr>
  <td><code>custom</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#any">Any</a> (oneof )</td>
  <td>For proxies that support custom circuit breaker policies.</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.CircuitBreaker.SimpleCircuitBreakerPolicy"></a>
### SimpleCircuitBreakerPolicy

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.CircuitBreaker.SimpleCircuitBreakerPolicy.max_connections"></a>
 <tr>
  <td><code>max_connections</code></td>
  <td>int32</td>
  <td>Maximum number of connections to a backend.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.CircuitBreaker.SimpleCircuitBreakerPolicy.http_max_pending_requests"></a>
 <tr>
  <td><code>http_max_pending_requests</code></td>
  <td>int32</td>
  <td>Maximum number of pending requests to a backend.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.CircuitBreaker.SimpleCircuitBreakerPolicy.http_max_requests"></a>
 <tr>
  <td><code>http_max_requests</code></td>
  <td>int32</td>
  <td>Maximum number of requests to a backend.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.CircuitBreaker.SimpleCircuitBreakerPolicy.sleep_window"></a>
 <tr>
  <td><code>sleep_window</code></td>
  <td>double</td>
  <td>Minimum time the circuit will be closed. In floating point seconds format.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.CircuitBreaker.SimpleCircuitBreakerPolicy.http_consecutive_errors"></a>
 <tr>
  <td><code>http_consecutive_errors</code></td>
  <td>int32</td>
  <td>Number of 5XX errors before circuit is opened.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.CircuitBreaker.SimpleCircuitBreakerPolicy.http_detection_interval"></a>
 <tr>
  <td><code>http_detection_interval</code></td>
  <td>double</td>
  <td>Interval for checking state of hystrix circuit.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.CircuitBreaker.SimpleCircuitBreakerPolicy.http_max_requests_per_connection"></a>
 <tr>
  <td><code>http_max_requests_per_connection</code></td>
  <td>int32</td>
  <td>Maximum number of requests per connection to a backend.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.CircuitBreaker.SimpleCircuitBreakerPolicy.http_max_ejection_percent"></a>
 <tr>
  <td><code>http_max_ejection_percent</code></td>
  <td>int32</td>
  <td>Maximum % of hosts in the destination service that can be ejected due to circuit breaking. Defaults to 10%.</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.DestinationPolicy"></a>
### DestinationPolicy
DestinationPolicy declares policies that determine how to handle traffic for a
destination service (load balancing policies, failure recovery policies such
as timeouts, retries, circuit breakers, etc).  Policies are applicable per
individual service versions. ONLY ONE policy can be defined per service version.
/
Note that these policies are enforced on client-side connections or
requests, i.e., enforced when the service is opening a
connection/sending a request via the proxy to the destination.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.DestinationPolicy.destination"></a>
 <tr>
  <td><code>destination</code></td>
  <td>string</td>
  <td>REQUIRED. Service name for which the service version is defined. The value MUST be a fully-qualified domain name, e.g. "my-service.default.svc.cluster.local".</td>
 </tr>
<a name="istio.proxy.v1alpha.config.DestinationPolicy.tags"></a>
 <tr>
  <td><code>tags</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td>Service version destination identifier for the destination service. The identifier is qualified by the destination service name, e.g. version "env=prod" in "my-service.default.svc.cluster.local". N.B. The map is used instead of pstruct due to lack of serialization support in golang protobuf library (see <a href="https://github.com/golang/protobuf/pull/208">https://github.com/golang/protobuf/pull/208</a>)</td>
 </tr>
<a name="istio.proxy.v1alpha.config.DestinationPolicy.load_balancing"></a>
 <tr>
  <td><code>load_balancing</code></td>
  <td><a href="#istio.proxy.v1alpha.config.LoadBalancing">LoadBalancing</a></td>
  <td>Load balancing policy</td>
 </tr>
<a name="istio.proxy.v1alpha.config.DestinationPolicy.circuit_breaker"></a>
 <tr>
  <td><code>circuit_breaker</code></td>
  <td><a href="#istio.proxy.v1alpha.config.CircuitBreaker">CircuitBreaker</a></td>
  <td>Circuit breaker policy</td>
 </tr>
<a name="istio.proxy.v1alpha.config.DestinationPolicy.custom"></a>
 <tr>
  <td><code>custom</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#any">Any</a></td>
  <td>Other custom policy implementations</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.DestinationWeight"></a>
### DestinationWeight
Each routing rule is associated with one or more service versions (see
glossary in beginning of document). Weights associated with the version
determine the proportion of traffic it receives.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.DestinationWeight.destination"></a>
 <tr>
  <td><code>destination</code></td>
  <td>string</td>
  <td>Destination uniquely identifies the destination service. If not specified, the value is inherited from the parent route rule. Value must be in fully qualified domain name format (e.g., "my-service.default.svc.cluster.local").</td>
 </tr>
<a name="istio.proxy.v1alpha.config.DestinationWeight.tags"></a>
 <tr>
  <td><code>tags</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td>Service version identifier for the destination service. N.B. The map is used instead of pstruct due to lack of serialization support in golang protobuf library (see <a href="https://github.com/golang/protobuf/pull/208">https://github.com/golang/protobuf/pull/208</a>)</td>
 </tr>
<a name="istio.proxy.v1alpha.config.DestinationWeight.weight"></a>
 <tr>
  <td><code>weight</code></td>
  <td>int32</td>
  <td>The proportion of traffic to be forwarded to the service version. Max is 100. Sum of weights across destinations should add up to 100. If there is only destination in a rule, the weight value is assumed to be 100.</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.HTTPFaultInjection"></a>
### HTTPFaultInjection
Faults can be injected into the API calls by the proxy, for testing the
failure recovery capabilities of downstream services.  Faults include
aborting the Http request from downstream service, delaying the proxying of
requests, or both. MUST specify either delay or abort or both.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPFaultInjection.delay"></a>
 <tr>
  <td><code>delay</code></td>
  <td><a href="#istio.proxy.v1alpha.config.HTTPFaultInjection.Delay">Delay</a></td>
  <td>Delay requests before forwarding, emulating various failures such as network issues, overloaded upstream service, etc.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPFaultInjection.abort"></a>
 <tr>
  <td><code>abort</code></td>
  <td><a href="#istio.proxy.v1alpha.config.HTTPFaultInjection.Abort">Abort</a></td>
  <td>Abort Http request attempts and return error codes back to downstream service, giving the impression that the upstream service is faulty. N.B. Both delay and abort can be specified simultaneously. Delay and Abort are independent of one another. For e.g., if Delay is restricted to 5% of requests while Abort is restricted to 10% of requests, the 10% in abort specification applies to all requests directed to the service. It may be the case that one or more requests being aborted were also delayed.</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.HTTPFaultInjection.Abort"></a>
### Abort
Abort Http request attempts and return error codes back to downstream
service.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPFaultInjection.Abort.percent"></a>
 <tr>
  <td><code>percent</code></td>
  <td>float</td>
  <td>percentage of requests to be aborted with the error code provided.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPFaultInjection.Abort.override_header_name"></a>
 <tr>
  <td><code>override_header_name</code></td>
  <td>string</td>
  <td>Specify abort code as part of Http request.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPFaultInjection.Abort.grpc_status"></a>
 <tr>
  <td><code>grpc_status</code></td>
  <td>string (oneof )</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPFaultInjection.Abort.http2_error"></a>
 <tr>
  <td><code>http2_error</code></td>
  <td>string (oneof )</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPFaultInjection.Abort.http_status"></a>
 <tr>
  <td><code>http_status</code></td>
  <td>int32 (oneof )</td>
  <td></td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.HTTPFaultInjection.Delay"></a>
### Delay
MUST specify either a fixed delay or exponential delay. Exponential
delay is unsupported at the moment.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPFaultInjection.Delay.percent"></a>
 <tr>
  <td><code>percent</code></td>
  <td>float</td>
  <td>percentage of requests on which the delay will be injected</td>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPFaultInjection.Delay.override_header_name"></a>
 <tr>
  <td><code>override_header_name</code></td>
  <td>string</td>
  <td>Specify delay duration as part of Http request.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPFaultInjection.Delay.fixed_delay"></a>
 <tr>
  <td><code>fixed_delay</code></td>
  <td>double (oneof )</td>
  <td>Add a fixed delay before forwarding the request. Delay duration in seconds.nanoseconds</td>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPFaultInjection.Delay.exponential_delay"></a>
 <tr>
  <td><code>exponential_delay</code></td>
  <td>double (oneof )</td>
  <td>Add a delay (based on an exponential function) before forwarding the request. mean delay needed to derive the exponential delay values</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.HTTPRetry"></a>
### HTTPRetry
Retry policy to use when a request fails.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPRetry.simple_retry"></a>
 <tr>
  <td><code>simple_retry</code></td>
  <td><a href="#istio.proxy.v1alpha.config.HTTPRetry.SimpleRetryPolicy">SimpleRetryPolicy</a> (oneof )</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPRetry.custom"></a>
 <tr>
  <td><code>custom</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#any">Any</a> (oneof )</td>
  <td>For proxies that support custom retry policies</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.HTTPRetry.SimpleRetryPolicy"></a>
### SimpleRetryPolicy

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPRetry.SimpleRetryPolicy.attempts"></a>
 <tr>
  <td><code>attempts</code></td>
  <td>int32</td>
  <td>Number of retries for a given request. The interval between retries will be determined automatically (25ms+). Actual number of retries attempted depends on the http_timeout</td>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPRetry.SimpleRetryPolicy.per_try_timeout"></a>
 <tr>
  <td><code>per_try_timeout</code></td>
  <td>double</td>
  <td>Timeout per retry attempt for a given request. Specified in seconds.nanoseconds format.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPRetry.SimpleRetryPolicy.override_header_name"></a>
 <tr>
  <td><code>override_header_name</code></td>
  <td>string</td>
  <td>Downstream Service could specify retry attempts via Http header to the proxy, if the proxy supports such a feature.</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.HTTPTimeout"></a>
### HTTPTimeout
Request timeout: wait time until a response is received. Does not
indicate the time for the entire response to arrive.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPTimeout.simple_timeout"></a>
 <tr>
  <td><code>simple_timeout</code></td>
  <td><a href="#istio.proxy.v1alpha.config.HTTPTimeout.SimpleTimeoutPolicy">SimpleTimeoutPolicy</a> (oneof )</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPTimeout.custom"></a>
 <tr>
  <td><code>custom</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#any">Any</a> (oneof )</td>
  <td>For proxies that support custom timeout policies</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.HTTPTimeout.SimpleTimeoutPolicy"></a>
### SimpleTimeoutPolicy

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPTimeout.SimpleTimeoutPolicy.timeout"></a>
 <tr>
  <td><code>timeout</code></td>
  <td>double</td>
  <td>Timeout for a HTTP request. Includes retries as well. Unit is in floating point seconds. Default 15 seconds. Specified in seconds.nanoseconds format</td>
 </tr>
<a name="istio.proxy.v1alpha.config.HTTPTimeout.SimpleTimeoutPolicy.override_header_name"></a>
 <tr>
  <td><code>override_header_name</code></td>
  <td>string</td>
  <td>Downstream service could specify timeout via Http header to the proxy, if the proxy supports such a feature.</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.L4FaultInjection"></a>
### L4FaultInjection
/@exclude Faults can be injected into the connections from downstream by the
proxy, for testing the failure recovery capabilities of downstream
services.  Faults include aborting the connection from downstream
service, delaying the proxying of connection to the destination
service, and throttling the bandwidth of the connection (either
end). Bandwidth throttling for failure testing should not be confused
with the rate limiting policy enforcement provided by the Mixer
component. L4 fault injection is not supported at the moment.
Unlike Http services, we have very little context for raw Tcp|Udp
connections. We could throttle bandwidth of the connections (slow down
the connection) and/or abruptly reset (terminate) the Tcp connection
after it has been established.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.L4FaultInjection.throttle"></a>
 <tr>
  <td><code>throttle</code></td>
  <td><a href="#istio.proxy.v1alpha.config.L4FaultInjection.Throttle">Throttle</a></td>
  <td>We first throttle (if set) and then terminate the connection.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.L4FaultInjection.terminate"></a>
 <tr>
  <td><code>terminate</code></td>
  <td><a href="#istio.proxy.v1alpha.config.L4FaultInjection.Terminate">Terminate</a></td>
  <td></td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.L4FaultInjection.Terminate"></a>
### Terminate
Abruptly reset (terminate) the Tcp connection after it has been
established, emulating remote server crash or link failure.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.L4FaultInjection.Terminate.percent"></a>
 <tr>
  <td><code>percent</code></td>
  <td>float</td>
  <td>percentage of established Tcp connections to be terminated/reset</td>
 </tr>
<a name="istio.proxy.v1alpha.config.L4FaultInjection.Terminate.terminate_after_period"></a>
 <tr>
  <td><code>terminate_after_period</code></td>
  <td>double</td>
  <td></td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.L4FaultInjection.Throttle"></a>
### Throttle
Bandwidth throttling for Tcp and Udp connections

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.L4FaultInjection.Throttle.percent"></a>
 <tr>
  <td><code>percent</code></td>
  <td>float</td>
  <td>percentage of connections to throttle.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.L4FaultInjection.Throttle.downstream_limit_bps"></a>
 <tr>
  <td><code>downstream_limit_bps</code></td>
  <td>int64</td>
  <td>bandwidth limit in "bits" per second between downstream and proxy</td>
 </tr>
<a name="istio.proxy.v1alpha.config.L4FaultInjection.Throttle.upstream_limit_bps"></a>
 <tr>
  <td><code>upstream_limit_bps</code></td>
  <td>int64</td>
  <td>bandwidth limits in "bits" per second between proxy and upstream</td>
 </tr>
<a name="istio.proxy.v1alpha.config.L4FaultInjection.Throttle.throttle_for_period"></a>
 <tr>
  <td><code>throttle_for_period</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#doublevalue">DoubleValue</a></td>
  <td>Stop throttling after the given duration. If not set, the connection will be throttled for its lifetime.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.L4FaultInjection.Throttle.throttle_after_period"></a>
 <tr>
  <td><code>throttle_after_period</code></td>
  <td>double (oneof )</td>
  <td>Wait for X seconds after the connection is established, before starting bandwidth throttling. This would allow us to inject fault after the application protocol (e.g., MySQL) has had time to establish sessions/whatever handshake necessary.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.L4FaultInjection.Throttle.throttle_after_bytes"></a>
 <tr>
  <td><code>throttle_after_bytes</code></td>
  <td>double (oneof )</td>
  <td>Alternatively, we could wait for a certain number of bytes to be transferred to upstream before throttling the bandwidth.</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.L4MatchAttributes"></a>
### L4MatchAttributes
L4 connection match attributes. Note that L4 connection matching
support is incomplete.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.L4MatchAttributes.source_subnet"></a>
 <tr>
  <td><code>source_subnet[]</code></td>
  <td>repeated string</td>
  <td>IPv4 or IPv6 ip address with optional subnet. E.g., a.b.c.d/xx form or just a.b.c.d</td>
 </tr>
<a name="istio.proxy.v1alpha.config.L4MatchAttributes.destination_subnet"></a>
 <tr>
  <td><code>destination_subnet[]</code></td>
  <td>repeated string</td>
  <td>IPv4 or IPv6 ip address of destination with optional subnet. E.g., a.b.c.d/xx form or just a.b.c.d. This is only valid when the destination service has several IPs and the application explicitly specifies a particular IP.</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.LoadBalancing"></a>
### LoadBalancing
Load balancing policy to use when forwarding traffic.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.LoadBalancing.name"></a>
 <tr>
  <td><code>name</code></td>
  <td><a href="#istio.proxy.v1alpha.config.LoadBalancing.SimpleLBPolicy">SimpleLBPolicy</a> (oneof )</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1alpha.config.LoadBalancing.custom"></a>
 <tr>
  <td><code>custom</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#any">Any</a> (oneof )</td>
  <td>/Custom LB policy implementations</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.LoadBalancing.SimpleLBPolicy"></a>
### SimpleLBPolicy
Common load balancing policies supported in Istio service mesh.


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.LoadBalancing.SimpleLBPolicy.ROUND_ROBIN"></a>
 <tr>
  <td>ROUND_ROBIN</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1alpha.config.LoadBalancing.SimpleLBPolicy.LEAST_CONN"></a>
 <tr>
  <td>LEAST_CONN</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1alpha.config.LoadBalancing.SimpleLBPolicy.RANDOM"></a>
 <tr>
  <td>RANDOM</td>
  <td>Envoy has IP_HASH, but requires a HTTP header name to hash on</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.MatchCondition"></a>
### MatchCondition
Match condition specifies a set of criterion to be met in order for the
route rule to be applied to the connection or HTTP request.  The
condition provides distinct set of conditions for each protocol with
the intention that conditions apply only to the service ports that
match the protocol.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.MatchCondition.source"></a>
 <tr>
  <td><code>source</code></td>
  <td>string</td>
  <td>Identifies the service initiating a connection or a request by its name. If specified, name MUST BE a fully qualified domain name such as foo.bar.com</td>
 </tr>
<a name="istio.proxy.v1alpha.config.MatchCondition.source_tags"></a>
 <tr>
  <td><code>source_tags</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td>Identifies the source service version. The identifier is interpreted by the platform to match a service version for the source service. N.B. The map is used instead of pstruct due to lack of serialization support in golang protobuf library (see <a href="https://github.com/golang/protobuf/pull/208">https://github.com/golang/protobuf/pull/208</a>)</td>
 </tr>
<a name="istio.proxy.v1alpha.config.MatchCondition.tcp"></a>
 <tr>
  <td><code>tcp</code></td>
  <td><a href="#istio.proxy.v1alpha.config.L4MatchAttributes">L4MatchAttributes</a></td>
  <td>Set of layer 4 match conditions based on the IP ranges. INCOMPLETE implementation</td>
 </tr>
<a name="istio.proxy.v1alpha.config.MatchCondition.udp"></a>
 <tr>
  <td><code>udp</code></td>
  <td><a href="#istio.proxy.v1alpha.config.L4MatchAttributes">L4MatchAttributes</a></td>
  <td>Set of layer 4 match conditions based on the IP ranges</td>
 </tr>
<a name="istio.proxy.v1alpha.config.MatchCondition.http_headers"></a>
 <tr>
  <td><code>http_headers</code></td>
  <td>repeated map&lt;string, <a href="#istio.proxy.v1alpha.config.StringMatch">StringMatch</a>&gt;</td>
  <td>Set of HTTP match conditions based on HTTP/1.1, HTTP/2, GRPC request metadata, such as "uri", "scheme", "authority". The header keys are case-insensitive.</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.ProxyMeshConfig"></a>
### ProxyMeshConfig
ProxyMeshConfig defines variables shared by all proxies in the Istio
service mesh.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.egress_proxy_address"></a>
 <tr>
  <td><code>egress_proxy_address</code></td>
  <td>string</td>
  <td>Address of the egress proxy service (e.g. "istio-egress:80")</td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.discovery_address"></a>
 <tr>
  <td><code>discovery_address</code></td>
  <td>string</td>
  <td>Address of the discovery service exposing SDS, CDS, RDS (e.g. "manager:8080")</td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.mixer_address"></a>
 <tr>
  <td><code>mixer_address</code></td>
  <td>string</td>
  <td>Address of the mixer service (e.g. "mixer:9090")</td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.proxy_listen_port"></a>
 <tr>
  <td><code>proxy_listen_port</code></td>
  <td>int32</td>
  <td>Port opened by the proxy for the traffic capture</td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.proxy_admin_port"></a>
 <tr>
  <td><code>proxy_admin_port</code></td>
  <td>int32</td>
  <td>Port opened by the proxy for the administrative interface</td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.drain_duration"></a>
 <tr>
  <td><code>drain_duration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Duration of the grace period to drain connections from the parent proxy instance</td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.parent_shutdown_duration"></a>
 <tr>
  <td><code>parent_shutdown_duration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Duration to wait before shutting down the parent proxy instance</td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.istio_service_cluster"></a>
 <tr>
  <td><code>istio_service_cluster</code></td>
  <td>string</td>
  <td>IstioServiceCluster defines the name for the service_cluster that is shared by all proxy instances. Since Istio does not assign a local service/service version to each proxy instance, the name is same for all of them. This setting corresponds to "--service-cluster" flag in Envoy. The value for "--service-node" is used by the proxy to identify its set of local instances to RDS for source-based routing. For example, if proxy sends its IP address, the RDS can compute routes that are relative to the service instances located at that IP address.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.discovery_refresh_delay"></a>
 <tr>
  <td><code>discovery_refresh_delay</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Delay between polling requests to the discovery service</td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.connect_timeout"></a>
 <tr>
  <td><code>connect_timeout</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Connection timeout used by the Envoy clusters</td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.ingress_class"></a>
 <tr>
  <td><code>ingress_class</code></td>
  <td>string</td>
  <td>Class of ingress resources to be processed by Istio ingress controller. This corresponds to the value of "kubernetes.io/ingress.class" annotation.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.ingress_controller_mode"></a>
 <tr>
  <td><code>ingress_controller_mode</code></td>
  <td><a href="#istio.proxy.v1alpha.config.ProxyMeshConfig.IngressControllerMode">IngressControllerMode</a></td>
  <td>Defines whether to use Istio ingress proxy for annotated or all ingress resources</td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.auth_policy"></a>
 <tr>
  <td><code>auth_policy</code></td>
  <td><a href="#istio.proxy.v1alpha.config.ProxyMeshConfig.AuthPolicy">AuthPolicy</a></td>
  <td>Authentication policy defines the global switch to control authentication for proxy-to-proxy communication</td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.auth_certs_path"></a>
 <tr>
  <td><code>auth_certs_path</code></td>
  <td>string</td>
  <td>Path to the secrets used by the authentication policy</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.AuthPolicy"></a>
### AuthPolicy


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.AuthPolicy.NONE"></a>
 <tr>
  <td>NONE</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.AuthPolicy.MUTUAL_TLS"></a>
 <tr>
  <td>MUTUAL_TLS</td>
  <td>Proxy to proxy traffic is wrapped into mutual TLS connections</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.IngressControllerMode"></a>
### IngressControllerMode


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.IngressControllerMode.OFF"></a>
 <tr>
  <td>OFF</td>
  <td>Disables Ingress controller.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.IngressControllerMode.DEFAULT"></a>
 <tr>
  <td>DEFAULT</td>
  <td>Ingress resources are applied if annotated with the configured ingress class, or not annotated with an ingress class at all. This mode is suitable for a controller running as the cluster's default ingress controller, which is expected to also process ingress resources not annotated at all.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.ProxyMeshConfig.IngressControllerMode.STRICT"></a>
 <tr>
  <td>STRICT</td>
  <td>Ingress resources are applied only if annotated with the configured ingress class. This mode is suitable for a controller which is a running as a secondary ingress controller (e.g., in addition to a cloud-provided ingress controller).</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.RouteRule"></a>
### RouteRule
Route rule provides a custom routing policy based on the source and
destination service versions and connection/request metadata.  The rule must
provide a set of conditions for each protocol (TCP, UDP, HTTP) that the
destination service exposes on its ports. The rule applies only to the ports
on the destination service for which it provides protocol-specific match
condition, e.g. if the rule does not specify TCP condition, the rule does
not apply to TCP traffic towards the destination service.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.RouteRule.destination"></a>
 <tr>
  <td><code>destination</code></td>
  <td>string</td>
  <td>REQUIRED: Destination uniquely identifies the destination associated with this routing rule. This field is applicable for hostname-based resolution for HTTP traffic as well as IP-based resolution for TCP/UDP traffic. The value MUST be a fully-qualified domain name, e.g. "my-service.default.svc.cluster.local".</td>
 </tr>
<a name="istio.proxy.v1alpha.config.RouteRule.precedence"></a>
 <tr>
  <td><code>precedence</code></td>
  <td>int32</td>
  <td>Precedence is used to disambiguate the order of application of rules for the same destination service. A higher number takes priority. If not specified, the value is assumed to be 0. The order of application for rules with the same precedence is unspecified.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.RouteRule.match"></a>
 <tr>
  <td><code>match</code></td>
  <td><a href="#istio.proxy.v1alpha.config.MatchCondition">MatchCondition</a></td>
  <td>Optional match condtions to be satisfied for the route rule to be activated. If match is omitted, the route rule applies only to HTTP traffic.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.RouteRule.route"></a>
 <tr>
  <td><code>route[]</code></td>
  <td>repeated <a href="#istio.proxy.v1alpha.config.DestinationWeight">DestinationWeight</a></td>
  <td>Each routing rule is associated with one or more service version destinations (see glossary in beginning of document). Weights associated with the service version determine the proportion of traffic it receives.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.RouteRule.http_req_timeout"></a>
 <tr>
  <td><code>http_req_timeout</code></td>
  <td><a href="#istio.proxy.v1alpha.config.HTTPTimeout">HTTPTimeout</a></td>
  <td>Timeout policy for HTTP requests.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.RouteRule.http_req_retries"></a>
 <tr>
  <td><code>http_req_retries</code></td>
  <td><a href="#istio.proxy.v1alpha.config.HTTPRetry">HTTPRetry</a></td>
  <td>Retry policy for HTTP requests.</td>
 </tr>
<a name="istio.proxy.v1alpha.config.RouteRule.http_fault"></a>
 <tr>
  <td><code>http_fault</code></td>
  <td><a href="#istio.proxy.v1alpha.config.HTTPFaultInjection">HTTPFaultInjection</a></td>
  <td>/L7 fault injection policy applies to Http traffic</td>
 </tr>
<a name="istio.proxy.v1alpha.config.RouteRule.l4_fault"></a>
 <tr>
  <td><code>l4_fault</code></td>
  <td><a href="#istio.proxy.v1alpha.config.L4FaultInjection">L4FaultInjection</a></td>
  <td>/@exclude L4 fault injection policy applies to Tcp/Udp (not Http) traffic</td>
 </tr>
</table>

<a name="istio.proxy.v1alpha.config.StringMatch"></a>
### StringMatch
Describes how to matches a given string (exact match, prefix-based
match or posix style regex based match). Match is case-sensitive. NOTE:
use of regex depends on the specific proxy implementation.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1alpha.config.StringMatch.exact"></a>
 <tr>
  <td><code>exact</code></td>
  <td>string (oneof )</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1alpha.config.StringMatch.prefix"></a>
 <tr>
  <td><code>prefix</code></td>
  <td>string (oneof )</td>
  <td></td>
 </tr>
<a name="istio.proxy.v1alpha.config.StringMatch.regex"></a>
 <tr>
  <td><code>regex</code></td>
  <td>string (oneof )</td>
  <td></td>
 </tr>
</table>
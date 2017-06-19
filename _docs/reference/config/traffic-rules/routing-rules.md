---
title: Routing Rules
overview: Traffic routing rule configuration schema

order: 20

layout: docs
type: markdown
---


<a name="istio.proxy.v1.config.RouteRule"></a>
### RouteRule

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


    destination: reviews.default.svc.cluster.local
    route:
    - tags:
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
  <td>string</td>
  <td>REQUIRED: Destination uniquely identifies the destination associated with this routing rule. This field is applicable for hostname-based resolution for HTTP traffic as well as IP-based resolution for TCP/UDP traffic. The value MUST BE a fully-qualified domain name, e.g. "my-service.default.svc.cluster.local".</td>
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
</table>

<a name="istio.proxy.v1.config.MatchCondition"></a>
### MatchCondition
Match condition specifies a set of criterion to be met in order for the
route rule to be applied to the connection or HTTP request.  The
condition provides distinct set of conditions for each protocol with the
intention that conditions apply only to the service ports that match the
protocol. For example, the following route rule restricts the rule to
match only requests originating from "reviews:v2", accessing ratings
service where the URL path starts with /ratings/v2/ and the request
contains a "cookie" with value "user=jason",


    destination: ratings.default.svc.cluster.local
    match:
      source: reviews.default.svc.cluster.local
      sourceTags:
        version: v2
      httpHeaders:
        cookie:
          regex: "^(.*?;)?(user=jason)(;.*)?$"
        uri:
          prefix: "/ratings/v2/"


MatchCondition CANNOT BE empty. At least one of source, sourceTags or
httpHeaders must be specified.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.proxy.v1.config.MatchCondition.source"></a>
 <tr>
  <td><code>source</code></td>
  <td>string</td>
  <td>Identifies the service initiating a connection or a request by its name. If specified, name MUST BE a fully qualified domain name such as foo.bar.com</td>
 </tr>
<a name="istio.proxy.v1.config.MatchCondition.sourceTags"></a>
 <tr>
  <td><code>sourceTags</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td>One or more tags that uniquely identify the source service version. In Kubernetes, tags correspond to the labels associated with pods.</td>
 </tr>
<a name="istio.proxy.v1.config.MatchCondition.httpHeaders"></a>
 <tr>
  <td><code>httpHeaders</code></td>
  <td>repeated map&lt;string, <a href="#istio.proxy.v1.config.StringMatch">StringMatch</a>&gt;</td>
  <td><p>Set of HTTP match conditions based on HTTP/1.1, HTTP/2, GRPC request metadata, such as <em>uri</em>, <em>scheme</em>, <em>authority</em>. The header keys must be lowercase and use hyphen as the separator, e.g. <em>x-request-id</em>.</p><p><em>Note 1:</em> The keys <em>uri</em>, <em>scheme</em>, <em>method</em>, and <em>authority</em> correspond to URI, protocol scheme (e.g., HTTP, HTTPS), HTTP method (e.g., GET, POST), and the HTTP Host header respectively.</p><p><em>Note 2:</em> <em>uri</em> can be used to perform URL matches. For URL matches (Uri_), only prefix and exact (see StringMatch) matches are supported. For other HTTP headers, exact, prefix and ECMA style regular expression matches are supported.</p></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.StringMatch"></a>
#### StringMatch
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

<a name="istio.proxy.v1.config.DestinationWeight"></a>
### DestinationWeight
Each routing rule is associated with one or more service versions (see
glossary in beginning of document). Weights associated with the version
determine the proportion of traffic it receives. For example, the
following rule will route 25% of traffic for the "reviews" service to
instances with the "v2" tag and the remaining traffic (i.e., 75%) to
"v1".


    destination: reviews.default.svc.cluster.local
    route:
    - tags:
        version: v2
      weight: 25
    - tags:
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
  <td>string</td>
  <td>Destination uniquely identifies the destination service. If not specified, the value is inherited from the parent route rule. Value must be in fully qualified domain name format (e.g., "my-service.default.svc.cluster.local").</td>
 </tr>
<a name="istio.proxy.v1.config.DestinationWeight.tags"></a>
 <tr>
  <td><code>tags</code></td>
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

<a name="istio.proxy.v1.config.HTTPRedirect"></a>
### HTTPRedirect
HTTPRedirect can be used to send a 302 redirect response to the caller,
where the Authority/Host and the URI in the response can be swapped with
the specified values. For example, the following route rule redirects
requests for /v1/getProductRatings API on the ratings service to
/v1/bookRatings provided by the bookratings service.


    destination: ratings.default.svc.cluster.local
    match:
      httpHeaders:
        uri:
         exact: /v1/getProductRatings
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

<a name="istio.proxy.v1.config.HTTPRewrite"></a>
### HTTPRewrite
HTTPRewrite can be used to rewrite specific parts of a HTTP request
before forwarding the request to the destination. Rewrite primitive can
be used only with the DestinationWeights. The following example
demonstrates how to rewrite the URL prefix for api call (/ratings) to
ratings service before making the actual API call.


    destination: ratings.default.svc.cluster.local
    match:
      httpHeaders:
        uri:
         prefix: /ratings
    rewrite:
      uri: /v1/bookRatings
    route:
    - tags:
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


    destination: ratings.default.svc.cluster.local
    route:
    - tags:
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
  <td><a href="#istio.proxy.v1.config.HTTPTimeout.SimpleTimeoutPolicy">SimpleTimeoutPolicy</a></td>
  <td></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.HTTPTimeout.SimpleTimeoutPolicy"></a>
#### SimpleTimeoutPolicy

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
</table>

<a name="istio.proxy.v1.config.HTTPRetry"></a>
### HTTPRetry
Describes the retry policy to use when a HTTP request fails. For
example, the following rule sets the maximum number of retries to 3 when
calling ratings:v1 service, with a 2s timeout per retry attempt.


    destination: ratings.default.svc.cluster.local
    route:
    - tags:
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
  <td><a href="#istio.proxy.v1.config.HTTPRetry.SimpleRetryPolicy">SimpleRetryPolicy</a></td>
  <td></td>
 </tr>
</table>

<a name="istio.proxy.v1.config.HTTPRetry.SimpleRetryPolicy"></a>
#### SimpleRetryPolicy

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
#### Abort
Abort specification is used to prematurely abort a request with a
pre-specified error code. The following example will return an HTTP
400 error code for 10% of the requests to the "ratings" service "v1".


    destination: ratings.default.svc.cluster.local
    route:
    - tags:
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
<a name="istio.proxy.v1.config.HTTPFaultInjection.Abort.httpStatus"></a>
 <tr>
  <td><code>httpStatus</code></td>
  <td>int32</td>
  <td>REQUIRED. HTTP status code to use to abort the Http request.</td>
 </tr>
</table>

<a name="istio.proxy.v1.config.HTTPFaultInjection.Delay"></a>
#### Delay
Delay specification is used to inject latency into the request
forwarding path. The following example will introduce a 5 second delay
in 10% of the requests to the "v1" version of the "reviews"
service.


    destination: reviews.default.svc.cluster.local
    route:
    - tags:
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
<a name="istio.proxy.v1.config.HTTPFaultInjection.Delay.fixedDelay"></a>
 <tr>
  <td><code>fixedDelay</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>REQUIRED. Add a fixed delay before forwarding the request. Format: 1h/1m/1s/1ms. MUST be &gt;=1ms.</td>
 </tr>
</table>


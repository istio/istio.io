---
title: Rules: Fault Injection
overview: Generated documentation for the Istio's traffic management rules.

order: 1010

layout: docs
type: markdown
---


<a name="rpcIstio.proxy.v1.configIndex"></a>
### Index

* [HTTPFaultInjection](#istio.proxy.v1.config.HTTPFaultInjection)
(message)
* [HTTPFaultInjection.Abort](#istio.proxy.v1.config.HTTPFaultInjection.Abort)
(message)
* [HTTPFaultInjection.Delay](#istio.proxy.v1.config.HTTPFaultInjection.Delay)
(message)

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
### Delay
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

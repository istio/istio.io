---
title: Mixer Service
overview: Mixer's API Surface

order: 1200

layout: docs
type: markdown
---

<a name="istio.mixer.v1.Mixer"></a>
### Mixer
Mixer provides three core features:

- *Precondition Checking*. Enables callers to verify a number of preconditions
before responding to an incoming request from a service consumer.
Preconditions can include whether the service consumer is properly
authenticated, is on the service’s whitelist, passes ACL checks, and more.

- *Telemetry Reporting*. Enables services to report logging and monitoring.
In the future, it will also enable tracing and billing streams intended for
both the service operator as well as for service consumers.

- *Quota Management*. Enables services to allocate and free quota on a number
of dimensions, Quotas are used as a relatively simple resource management tool
to provide some fairness between service consumers when contending for limited
resources. Rate limits are examples of quotas.

<a name="istio.mixer.v1.Mixer.Check"></a>
#### Check
<code>
  rpc Check([CheckRequest](#istio.mixer.v1.CheckRequest)) returns ([CheckResponse](#istio.mixer.v1.CheckResponse))
</code>
Checks preconditions before performing an operation.
The preconditions enforced depend on the set of supplied attributes and
the active configuration.

<a name="istio.mixer.v1.Mixer.Quota"></a>
#### Quota
<code>
  rpc Quota([QuotaRequest](#istio.mixer.v1.QuotaRequest)) returns ([QuotaResponse](#istio.mixer.v1.QuotaResponse))
</code>
Quota allocates and releases quota.

<a name="istio.mixer.v1.Mixer.Report"></a>
#### Report
<code>
  rpc Report([ReportRequest](#istio.mixer.v1.ReportRequest)) returns ([ReportResponse](#istio.mixer.v1.ReportResponse))
</code>
Reports telemetry, such as logs and metrics.
The reported information depends on the set of supplied attributes and the
active configuration.

<a name="istio.mixer.v1.Attributes"></a>
### Attributes
An instance of this message is delivered to the mixer with every
API call.

The general idea is to leverage the stateful gRPC streams from the
proxy to the mixer to keep to a minimum the 'attribute chatter'.
Only delta attributes are sent over, multiple concurrent attribute
contexts can be used to avoid thrashing, and attribute indices are used to
keep the wire protocol maximally efficient.

Producing this message is the responsibility of the mixer's client
library which is linked into different proxy implementations.

The processing order for this state in the mixer is:

  * Any new dictionary is applied

  * The requested attribute context is looked up. If no such context has been defined, a
    new context is automatically created and initialized to the empty state. When a gRPC
    stream is first created, there are no attribute contexts for the stream.

  * If resetContext is true, then the attribute context is reset to the
    empty state.

  * All attributes to deleted are removed from the attribute context.

  * All attribute changes are applied to the attribute context.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.Attributes.dictionary"></a>
 <tr>
  <td><code>dictionary</code></td>
  <td>repeated map&lt;int32, string&gt;</td>
  <td><p>A dictionary that provides a mapping of shorthand index values to attribute names.</p><p>This is intended to leverage the stateful gRPC stream from the proxy to the mixer. This dictionary is sent over only when a stream to the mixer is first established and when the proxy's configuration changes and different attributes may be produced.</p><p>Once a dictionary has been sent over, it stays in effect until a new dictionary is sent to replace it. The first request sent on a stream must include a dictionary, otherwise the mixer can't process any attribute updates.</p><p>Dictionaries are independent of the attribute context and are thus global to each gRPC stream.</p></td>
 </tr>
<a name="istio.mixer.v1.Attributes.attributeContext"></a>
 <tr>
  <td><code>attributeContext</code></td>
  <td>int32</td>
  <td><p>The attribute context against which to operate.</p><p>The mixer keeps different contexts live for any proxy gRPC stream. This allows the proxy to maintain multiple concurrent 'bags of attributes' within the mixer.</p><p>If the proxy doesn't want to leverage multiple contexts, it just passes 0 here for every request.</p><p>The proxy is configured to use a maximum number of attribute contexts in order to prevent an explosion of contexts in the mixer's memory space.</p></td>
 </tr>
<a name="istio.mixer.v1.Attributes.resetContext"></a>
 <tr>
  <td><code>resetContext</code></td>
  <td>bool</td>
  <td><p>When true, resets the current attribute context to the empty state before applying any incoming attributes.</p><p>Resetting contexts is useful to constrain the amount of resources used by the mixer. The proxy needs to intelligently manage a pool of contexts. It may be useful to reset a context when certain big events happen, such as when an HTTP2 connection into the proxy terminates.</p></td>
 </tr>
<a name="istio.mixer.v1.Attributes.stringAttributes"></a>
 <tr>
  <td><code>stringAttributes</code></td>
  <td>repeated map&lt;int32, string&gt;</td>
  <td>Attributes being updated within the specified attribute context. These maps add and/or overwrite the context's current set of attributes.</td>
 </tr>
<a name="istio.mixer.v1.Attributes.int64Attributes"></a>
 <tr>
  <td><code>int64Attributes</code></td>
  <td>repeated map&lt;int32, int64&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.doubleAttributes"></a>
 <tr>
  <td><code>doubleAttributes</code></td>
  <td>repeated map&lt;int32, double&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.boolAttributes"></a>
 <tr>
  <td><code>boolAttributes</code></td>
  <td>repeated map&lt;int32, bool&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.timestampAttributes"></a>
 <tr>
  <td><code>timestampAttributes</code></td>
  <td>repeated map&lt;int32, <a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#timestamp">Timestamp</a>&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.durationAttributes"></a>
 <tr>
  <td><code>durationAttributes</code></td>
  <td>repeated map&lt;int32, <a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a>&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.bytesAttributes"></a>
 <tr>
  <td><code>bytesAttributes</code></td>
  <td>repeated map&lt;int32, bytes&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.stringMapAttributes"></a>
 <tr>
  <td><code>stringMapAttributes</code></td>
  <td>repeated map&lt;int32, <a href="#istio.mixer.v1.StringMap">StringMap</a>&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.deletedAttributes"></a>
 <tr>
  <td><code>deletedAttributes[]</code></td>
  <td>repeated int32</td>
  <td>Attributes that should be removed from the specified attribute context. Deleting attributes which aren't currently in the attribute context is not considered an error.</td>
 </tr>
<a name="istio.mixer.v1.Attributes.timestampAttributesHACK"></a>
 <tr>
  <td><code>timestampAttributesHACK</code></td>
  <td>repeated map&lt;int32, <a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#timestamp">Timestamp</a>&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.durationAttributesHACK"></a>
 <tr>
  <td><code>durationAttributesHACK</code></td>
  <td>repeated map&lt;int32, <a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a>&gt;</td>
  <td></td>
 </tr>
</table>

<a name="istio.mixer.v1.CheckRequest"></a>
### CheckRequest
Used to verify preconditions before performing an action.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.CheckRequest.requestIndex"></a>
 <tr>
  <td><code>requestIndex</code></td>
  <td>int64</td>
  <td>Index within the stream for this request, used to match to responses</td>
 </tr>
<a name="istio.mixer.v1.CheckRequest.attributeUpdate"></a>
 <tr>
  <td><code>attributeUpdate</code></td>
  <td><a href="#istio.mixer.v1.Attributes">Attributes</a></td>
  <td>The attributes to use for this request</td>
 </tr>
</table>

<a name="istio.mixer.v1.CheckResponse"></a>
### CheckResponse

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.CheckResponse.requestIndex"></a>
 <tr>
  <td><code>requestIndex</code></td>
  <td>int64</td>
  <td>Index of the request this response is associated with</td>
 </tr>
<a name="istio.mixer.v1.CheckResponse.attributeUpdate"></a>
 <tr>
  <td><code>attributeUpdate</code></td>
  <td><a href="#istio.mixer.v1.Attributes">Attributes</a></td>
  <td>The attributes to use for this response</td>
 </tr>
<a name="istio.mixer.v1.CheckResponse.result"></a>
 <tr>
  <td><code>result</code></td>
  <td><a href="./status.html">Status</a></td>
  <td>Indicates whether or not the preconditions succeeded</td>
 </tr>
<a name="istio.mixer.v1.CheckResponse.expiration"></a>
 <tr>
  <td><code>expiration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>The amount of time for which this result can be considered valid, given the same inputs</td>
 </tr>
</table>

<a name="istio.mixer.v1.QuotaRequest"></a>
### QuotaRequest

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.QuotaRequest.requestIndex"></a>
 <tr>
  <td><code>requestIndex</code></td>
  <td>int64</td>
  <td>Index within the stream for this request, used to match to responses</td>
 </tr>
<a name="istio.mixer.v1.QuotaRequest.attributeUpdate"></a>
 <tr>
  <td><code>attributeUpdate</code></td>
  <td><a href="#istio.mixer.v1.Attributes">Attributes</a></td>
  <td>The attributes to use for this request</td>
 </tr>
<a name="istio.mixer.v1.QuotaRequest.deduplicationId"></a>
 <tr>
  <td><code>deduplicationId</code></td>
  <td>string</td>
  <td>Used for deduplicating quota allocation/free calls in the case of failed RPCs and retries. This should be a UUID per call, where the same UUID is used for retries of the same quota allocation call.</td>
 </tr>
<a name="istio.mixer.v1.QuotaRequest.quota"></a>
 <tr>
  <td><code>quota</code></td>
  <td>string</td>
  <td>The quota to allocate from.</td>
 </tr>
<a name="istio.mixer.v1.QuotaRequest.amount"></a>
 <tr>
  <td><code>amount</code></td>
  <td>int64</td>
  <td>The amount of quota to allocate.</td>
 </tr>
<a name="istio.mixer.v1.QuotaRequest.bestEffort"></a>
 <tr>
  <td><code>bestEffort</code></td>
  <td>bool</td>
  <td>If true, allows a response to return less quota than requested. When false, the exact requested amount is returned or 0 if not enough quota was available.</td>
 </tr>
</table>

<a name="istio.mixer.v1.QuotaResponse"></a>
### QuotaResponse

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.QuotaResponse.requestIndex"></a>
 <tr>
  <td><code>requestIndex</code></td>
  <td>int64</td>
  <td>Index of the request this response is associated with.</td>
 </tr>
<a name="istio.mixer.v1.QuotaResponse.attributeUpdate"></a>
 <tr>
  <td><code>attributeUpdate</code></td>
  <td><a href="#istio.mixer.v1.Attributes">Attributes</a></td>
  <td>The attributes to use for this response</td>
 </tr>
<a name="istio.mixer.v1.QuotaResponse.result"></a>
 <tr>
  <td><code>result</code></td>
  <td><a href="./status.html">Status</a></td>
  <td>Indicates whether the quota request was successfully processed.</td>
 </tr>
<a name="istio.mixer.v1.QuotaResponse.expiration"></a>
 <tr>
  <td><code>expiration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>The amount of time the returned quota can be considered valid, this is 0 for non-expiring quotas.</td>
 </tr>
<a name="istio.mixer.v1.QuotaResponse.amount"></a>
 <tr>
  <td><code>amount</code></td>
  <td>int64</td>
  <td>The total amount of quota returned, may be less than requested.</td>
 </tr>
</table>

<a name="istio.mixer.v1.ReportRequest"></a>
### ReportRequest
Used to report telemetry after performing an action.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.ReportRequest.requestIndex"></a>
 <tr>
  <td><code>requestIndex</code></td>
  <td>int64</td>
  <td>Index within the stream for this request, used to match to responses</td>
 </tr>
<a name="istio.mixer.v1.ReportRequest.attributeUpdate"></a>
 <tr>
  <td><code>attributeUpdate</code></td>
  <td><a href="#istio.mixer.v1.Attributes">Attributes</a></td>
  <td>The attributes to use for this request</td>
 </tr>
</table>

<a name="istio.mixer.v1.ReportResponse"></a>
### ReportResponse

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.ReportResponse.requestIndex"></a>
 <tr>
  <td><code>requestIndex</code></td>
  <td>int64</td>
  <td>Index of the request this response is associated with</td>
 </tr>
<a name="istio.mixer.v1.ReportResponse.attributeUpdate"></a>
 <tr>
  <td><code>attributeUpdate</code></td>
  <td><a href="#istio.mixer.v1.Attributes">Attributes</a></td>
  <td>The attributes to use for this response</td>
 </tr>
<a name="istio.mixer.v1.ReportResponse.result"></a>
 <tr>
  <td><code>result</code></td>
  <td><a href="./status.html">Status</a></td>
  <td>Indicates whether the report was processed or not</td>
 </tr>
</table>

<a name="istio.mixer.v1.StringMap"></a>
### StringMap
A map of string to string. The keys in these maps are from the current
dictionary.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.StringMap.map"></a>
 <tr>
  <td><code>map</code></td>
  <td>repeated map&lt;int32, string&gt;</td>
  <td></td>
 </tr>
</table>

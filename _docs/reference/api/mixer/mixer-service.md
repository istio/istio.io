---
title: Mixer Service
overview: Generated documentation for Mixer's API Surface

order: 20

layout: docs
type: markdown
---


<a name="rpcIstio.mixer.v1"></a>
## Package istio.mixer.v1

<a name="rpcIstio.mixer.v1Index"></a>
### Index
* [Mixer](#istio.mixer.v1.Mixer) (interface)
* [Attributes](#istio.mixer.v1.Attributes)
(message)
* [CheckRequest](#istio.mixer.v1.CheckRequest)
(message)
* [CheckRequest.QuotaParams](#istio.mixer.v1.CheckRequest.QuotaParams)
(message)
* [CheckResponse](#istio.mixer.v1.CheckResponse)
(message)
* [CheckResponse.PreconditionResult](#istio.mixer.v1.CheckResponse.PreconditionResult)
(message)
* [CheckResponse.QuotaResult](#istio.mixer.v1.CheckResponse.QuotaResult)
(message)
* [ReferencedAttributes](#istio.mixer.v1.ReferencedAttributes)
(message)
* [ReferencedAttributes.AttributeMatch](#istio.mixer.v1.ReferencedAttributes.AttributeMatch)
(message)
* [ReferencedAttributes.Condition](#istio.mixer.v1.ReferencedAttributes.Condition)
(enum)
* [ReportRequest](#istio.mixer.v1.ReportRequest)
(message)
* [ReportResponse](#istio.mixer.v1.ReportResponse)
(message)
* [StringMap](#istio.mixer.v1.StringMap)
(message)

<a name="istio.mixer.v1.Mixer"></a>
### Mixer
Mixer provides three core features:

- *Precondition Checking*. Enables callers to verify a number of preconditions
before responding to an incoming request from a service consumer.
Preconditions can include whether the service consumer is properly
authenticated, is on the service’s whitelist, passes ACL checks, and more.

- *Quota Management*. Enables services to allocate and free quota on a number
of dimensions, Quotas are used as a relatively simple resource management tool
to provide some fairness between service consumers when contending for limited
resources. Rate limits are examples of quotas.

- *Telemetry Reporting*. Enables services to report logging and monitoring.
In the future, it will also enable tracing and billing streams intended for
both the service operator as well as for service consumers.

<a name="istio.mixer.v1.Mixer.Check"></a>
#### Check
<pre> rpc Check(<a href="#istio.mixer.v1.CheckRequest">CheckRequest</a>) returns (<a href="istio.mixer.v1.CheckResponse">CheckResponse</a>) </pre>

Checks preconditions and allocate quota before performing an operation.
The preconditions enforced depend on the set of supplied attributes and
the active configuration.

<a name="istio.mixer.v1.Mixer.Report"></a>
#### Report
<pre> rpc Report(<a href="#istio.mixer.v1.ReportRequest">ReportRequest</a>) returns (<a href="#istio.mixer.v1.ReportResponse">ReportResponse</a>) </pre>

Reports telemetry, such as logs and metrics.
The reported information depends on the set of supplied attributes and the
active configuration.

<a name="istio.mixer.v1.Attributes"></a>
### Attributes
Attributes represents a set of typed name/value pairs. Many of Mixer's
API either consume and/or return attributes.

Istio uses attributes to control the runtime behavior of services running in the service mesh.
Attributes are named and typed pieces of metadata describing ingress and egress traffic and the
environment this traffic occurs in. An Istio attribute carries a specific piece
of information such as the error code of an API request, the latency of an API request, or the
original IP address of a TCP connection. For example:


```
request.path: xyz/abc
request.size: 234
request.time: 12:34:56.789 04/17/2017
source.ip: 192.168.0.1
target.service: example
```


A given Istio deployment has a fixed vocabulary of attributes that it understands.
The specific vocabulary is determined by the set of attribute producers being used
in the deployment. The primary attribute producer in Istio is Envoy, although
specialized Mixer adapters and services can also generate attributes.

The common baseline set of attributes available in most Istio deployments is defined
[here](https://istio.io/docs/reference/config/mixer/attribute-vocabulary.html).

Attributes are strongly typed. The supported attribute types are defined by
[ValueType](https://github.com/istio/api/blob/master/mixer/v1/config/descriptor/value_type.proto).
Each type of value is encoded into one of the so-called transport types present
in this message.

Within this message, strings are referenced using integer indices into
one of two string dictionaries. Positive integers index into the global
deployment-wide dictionary, whereas negative integers index into the message-level
dictionary instead. The message-level dictionary is carried by the
`words` field of this message, the deployment-wide dictionary is determined via
configuration.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.Attributes.words"></a>
 <tr>
  <td><code>words[]</code></td>
  <td>repeated string</td>
  <td>The message-level dictionary.</td>
 </tr>
<a name="istio.mixer.v1.Attributes.strings"></a>
 <tr>
  <td><code>strings</code></td>
  <td>repeated map&lt;sint32, sint32&gt;</td>
  <td>Attribute payload. All <code>sint32</code> values represent indices into one of the word dictionaries. Positive values are indices into the global deployment-wide dictionary, negative values are indices into the message-level dictionary.</td>
 </tr>
<a name="istio.mixer.v1.Attributes.int64s"></a>
 <tr>
  <td><code>int64s</code></td>
  <td>repeated map&lt;sint32, int64&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.doubles"></a>
 <tr>
  <td><code>doubles</code></td>
  <td>repeated map&lt;sint32, double&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.bools"></a>
 <tr>
  <td><code>bools</code></td>
  <td>repeated map&lt;sint32, bool&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.timestamps"></a>
 <tr>
  <td><code>timestamps</code></td>
  <td>repeated map&lt;sint32, <a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#timestamp">Timestamp</a>&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.durations"></a>
 <tr>
  <td><code>durations</code></td>
  <td>repeated map&lt;sint32, <a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a>&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.bytes"></a>
 <tr>
  <td><code>bytes</code></td>
  <td>repeated map&lt;sint32, bytes&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.stringMaps"></a>
 <tr>
  <td><code>stringMaps</code></td>
  <td>repeated map&lt;sint32, <a href="#istio.mixer.v1.StringMap">StringMap</a>&gt;</td>
  <td></td>
 </tr>
</table>

<a name="istio.mixer.v1.CheckRequest"></a>
### CheckRequest
Used to get a thumbs-up/thumbs-down before performing an action.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.CheckRequest.attributes"></a>
 <tr>
  <td><code>attributes</code></td>
  <td><a href="#istio.mixer.v1.Attributes">Attributes</a></td>
  <td><p>The attributes to use for this request.</p><p>Mixer's configuration determines how these attributes are used to establish the result returned in the response.</p></td>
 </tr>
<a name="istio.mixer.v1.CheckRequest.globalWordCount"></a>
 <tr>
  <td><code>globalWordCount</code></td>
  <td>uint32</td>
  <td>The number of words in the global dictionary, used with to populate the attributes. This value is used as a quick way to determine whether the client is using a dictionary that the server understands.</td>
 </tr>
<a name="istio.mixer.v1.CheckRequest.deduplicationId"></a>
 <tr>
  <td><code>deduplicationId</code></td>
  <td>string</td>
  <td>Used for deduplicating <code>Check</code> calls in the case of failed RPCs and retries. This should be a UUID per call, where the same UUID is used for retries of the same call.</td>
 </tr>
<a name="istio.mixer.v1.CheckRequest.quotas"></a>
 <tr>
  <td><code>quotas</code></td>
  <td>repeated map&lt;string, <a href="#istio.mixer.v1.CheckRequest.QuotaParams">QuotaParams</a>&gt;</td>
  <td>The individual quotas to allocate</td>
 </tr>
</table>

<a name="istio.mixer.v1.CheckRequest.QuotaParams"></a>
### QuotaParams
parameters for a quota allocation

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.CheckRequest.QuotaParams.amount"></a>
 <tr>
  <td><code>amount</code></td>
  <td>int64</td>
  <td>Amount of quota to allocate</td>
 </tr>
<a name="istio.mixer.v1.CheckRequest.QuotaParams.bestEffort"></a>
 <tr>
  <td><code>bestEffort</code></td>
  <td>bool</td>
  <td>When true, supports returning less quota than what was requested.</td>
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
<a name="istio.mixer.v1.CheckResponse.precondition"></a>
 <tr>
  <td><code>precondition</code></td>
  <td><a href="#istio.mixer.v1.CheckResponse.PreconditionResult">PreconditionResult</a></td>
  <td>The precondition check results.</td>
 </tr>
<a name="istio.mixer.v1.CheckResponse.quotas"></a>
 <tr>
  <td><code>quotas</code></td>
  <td>repeated map&lt;string, <a href="#istio.mixer.v1.CheckResponse.QuotaResult">QuotaResult</a>&gt;</td>
  <td>The resulting quota, one entry per requested quota.</td>
 </tr>
</table>

<a name="istio.mixer.v1.CheckResponse.PreconditionResult"></a>
### PreconditionResult

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.CheckResponse.PreconditionResult.status"></a>
 <tr>
  <td><code>status</code></td>
  <td><a href="/docs/reference/api/mixer/status.html">Status</a></td>
  <td>A status code of OK indicates all preconditions were satisfied. Any other code indicates not all preconditions were satisfied and details describe why.</td>
 </tr>
<a name="istio.mixer.v1.CheckResponse.PreconditionResult.validDuration"></a>
 <tr>
  <td><code>validDuration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>The amount of time for which this result can be considered valid.</td>
 </tr>
<a name="istio.mixer.v1.CheckResponse.PreconditionResult.validUseCount"></a>
 <tr>
  <td><code>validUseCount</code></td>
  <td>int32</td>
  <td>The number of uses for which this result can be considered valid.</td>
 </tr>
<a name="istio.mixer.v1.CheckResponse.PreconditionResult.attributes"></a>
 <tr>
  <td><code>attributes</code></td>
  <td><a href="#istio.mixer.v1.Attributes">Attributes</a></td>
  <td><p>The attributes returned by Mixer.</p><p>The exact set of attributes returned is determined by the set of adapters Mixer is configured with. These attributes are used to ferry new attributes that Mixer derived based on the input set of attributes and its configuration.</p></td>
 </tr>
<a name="istio.mixer.v1.CheckResponse.PreconditionResult.referencedAttributes"></a>
 <tr>
  <td><code>referencedAttributes</code></td>
  <td><a href="#istio.mixer.v1.ReferencedAttributes">ReferencedAttributes</a></td>
  <td>The total set of attributes that were used in producing the result along with matching conditions.</td>
 </tr>
</table>

<a name="istio.mixer.v1.CheckResponse.QuotaResult"></a>
### QuotaResult

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.CheckResponse.QuotaResult.validDuration"></a>
 <tr>
  <td><code>validDuration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>The amount of time for which this result can be considered valid.</td>
 </tr>
<a name="istio.mixer.v1.CheckResponse.QuotaResult.grantedAmount"></a>
 <tr>
  <td><code>grantedAmount</code></td>
  <td>int64</td>
  <td>The amount of granted quota. When <code>QuotaParams.bestEffort</code> is true, this will be &gt;= 0. If <code>QuotaParams.bestEffort</code> is false, this will be either 0 or &gt;= <code>QuotaParams.amount</code>.</td>
 </tr>
<a name="istio.mixer.v1.CheckResponse.QuotaResult.referencedAttributes"></a>
 <tr>
  <td><code>referencedAttributes</code></td>
  <td><a href="#istio.mixer.v1.ReferencedAttributes">ReferencedAttributes</a></td>
  <td>The total set of attributes that were used in producing the result along with matching conditions.</td>
 </tr>
</table>

<a name="istio.mixer.v1.ReferencedAttributes"></a>
### ReferencedAttributes
Describes the attributes that were used to determine the response.
This can be used to construct a response cache.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.ReferencedAttributes.words"></a>
 <tr>
  <td><code>words[]</code></td>
  <td>repeated string</td>
  <td>The message-level dictionary. Refer to <a href="#istio.mixer.v1.Attributes">Attributes</a> for information on using dictionaries.</td>
 </tr>
<a name="istio.mixer.v1.ReferencedAttributes.attributeMatches"></a>
 <tr>
  <td><code>attributeMatches[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.ReferencedAttributes.AttributeMatch">AttributeMatch</a></td>
  <td>Describes a set of attributes.</td>
 </tr>
</table>

<a name="istio.mixer.v1.ReferencedAttributes.AttributeMatch"></a>
### AttributeMatch

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.ReferencedAttributes.AttributeMatch.name"></a>
 <tr>
  <td><code>name</code></td>
  <td>sint32</td>
  <td>The name of the attribute. This is a dictionary index encoded in a manner identical to all strings in the <a href="#istio.mixer.v1.Attributes">Attributes</a> message.</td>
 </tr>
<a name="istio.mixer.v1.ReferencedAttributes.AttributeMatch.condition"></a>
 <tr>
  <td><code>condition</code></td>
  <td><a href="#istio.mixer.v1.ReferencedAttributes.Condition">Condition</a></td>
  <td>The kind of match against the attribute value.</td>
 </tr>
<a name="istio.mixer.v1.ReferencedAttributes.AttributeMatch.regex"></a>
 <tr>
  <td><code>regex</code></td>
  <td>string</td>
  <td>The matching regex in the case of condition = REGEX</td>
 </tr>
</table>

<a name="istio.mixer.v1.ReferencedAttributes.Condition"></a>
### Condition
How an attribute's value was matched


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.ReferencedAttributes.Condition.CONDITION_UNSPECIFIED"></a>
 <tr>
  <td>CONDITION_UNSPECIFIED</td>
  <td>should not occur</td>
 </tr>
<a name="istio.mixer.v1.ReferencedAttributes.Condition.ABSENCE"></a>
 <tr>
  <td>ABSENCE</td>
  <td>match when attribute doesn't exist</td>
 </tr>
<a name="istio.mixer.v1.ReferencedAttributes.Condition.EXACT"></a>
 <tr>
  <td>EXACT</td>
  <td>match when attribute value is an exact byte-for-byte match</td>
 </tr>
<a name="istio.mixer.v1.ReferencedAttributes.Condition.REGEX"></a>
 <tr>
  <td>REGEX</td>
  <td>match when attribute value matches the included regex</td>
 </tr>
</table>

<a name="istio.mixer.v1.ReportRequest"></a>
### ReportRequest
Used to report telemetry after performing one or more actions.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.ReportRequest.attributes"></a>
 <tr>
  <td><code>attributes[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.Attributes">Attributes</a></td>
  <td><p>The attributes to use for this request.</p><p>Each <code>Attributes</code> element represents the state of a single action. Multiple actions can be provided in a single message in order to improve communication efficiency. The client can accumulate a set of actions and send them all in one single message.</p><p>Although each <code>Attributes</code> message is semantically treated as an independent stand-alone entity unrelated to the other attributes within the message, this message format leverages delta-encoding between attribute messages in order to substantially reduce the request size and improve end-to-end efficiency. Each individual set of attributes is used to modify the previous set. This eliminates the need to redundantly send the same attributes multiple times over within a single request.</p><p>If a client is not sophisticated and doesn't want to use delta-encoding, a degenerate case is to include all attributes in every individual message.</p></td>
 </tr>
<a name="istio.mixer.v1.ReportRequest.defaultWords"></a>
 <tr>
  <td><code>defaultWords[]</code></td>
  <td>repeated string</td>
  <td><p>The default message-level dictionary for all the attributes. Individual attribute messages can have their own dictionaries, but if they don't then this set of words, if it is provided, is used instead.</p><p>This makes it possible to share the same dictionary for all attributes in this request, which can substantially reduce the overall request size.</p></td>
 </tr>
<a name="istio.mixer.v1.ReportRequest.globalWordCount"></a>
 <tr>
  <td><code>globalWordCount</code></td>
  <td>uint32</td>
  <td>The number of words in the global dictionary. To detect global dictionary out of sync between client and server.</td>
 </tr>
</table>

<a name="istio.mixer.v1.ReportResponse"></a>
### ReportResponse

NOTE: _No fields in this message type.__

<a name="istio.mixer.v1.StringMap"></a>
### StringMap
A map of string to string. The keys and values in this map are dictionary
indices (see the [Attributes](#istio.mixer.v1.Attributes) message for an explanation)

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.StringMap.entries"></a>
 <tr>
  <td><code>entries</code></td>
  <td>repeated map&lt;sint32, sint32&gt;</td>
  <td></td>
 </tr>
</table>

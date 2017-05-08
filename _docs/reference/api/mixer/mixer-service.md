---
title: API
overview: Generated documentation for Mixer's API that is used by Envoy.

order: 20

layout: docs
type: markdown
---
<a name="rpc_istio.mixer.v1"></a>
## Package istio.mixer.v1

<a name="rpc_istio.mixer.v1_index"></a>
### Index
* [Mixer](#istio.mixer.v1.Mixer) (interface)
* [Attributes](#istio.mixer.v1.Attributes)
(message)
* [CheckRequest](#istio.mixer.v1.CheckRequest)
(message)
* [CheckResponse](#istio.mixer.v1.CheckResponse)
(message)
* [QuotaRequest](#istio.mixer.v1.QuotaRequest)
(message)
* [QuotaResponse](#istio.mixer.v1.QuotaResponse)
(message)
* [ReportRequest](#istio.mixer.v1.ReportRequest)
(message)
* [ReportResponse](#istio.mixer.v1.ReportResponse)
(message)
* [StringMap](#istio.mixer.v1.StringMap)
(message)

<a name="istio.mixer.v1.Mixer"></a>
### Mixer
The Mixer API

<a name="istio.mixer.v1.Mixer.Check"></a>
#### Check
<pre>
  rpc Check(<a href="#istio.mixer.v1.CheckRequest">CheckRequest</a>) returns (<a href="#istio.mixer.v1.CheckResponse">CheckResponse</a>)
</pre>
Checks preconditions before performing an operation.
The preconditions enforced depend on the set of supplied attributes
and the active configuration.

<a name="istio.mixer.v1.Mixer.Quota"></a>
#### Quota
<pre>
  rpc Quota(<a href="#istio.mixer.v1.QuotaRequest">QuotaRequest</a>) returns (<a href="#istio.mixer.v1.QuotaResponse">QuotaResponse</a>)
</pre>
Quota allocates and releases quota.

<a name="istio.mixer.v1.Mixer.Report"></a>
#### Report
<pre>
  rpc Report(<a href="#istio.mixer.v1.ReportRequest">ReportRequest</a>) returns (<a href="#istio.mixer.v1.ReportResponse">ReportResponse</a>)
</pre>
Reports telemetry, such as logs and metrics.
The reported information depends on the set of supplied attributes
and the active configuration.

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

  * If reset_context is true, then the attribute context is reset to the
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
<a name="istio.mixer.v1.Attributes.attribute_context"></a>
 <tr>
  <td><code>attribute_context</code></td>
  <td>int32</td>
  <td><p>The attribute context against which to operate.</p><p>The mixer keeps different contexts live for any proxy gRPC stream. This allows the proxy to maintain multiple concurrent 'bags of attributes' within the mixer.</p><p>If the proxy doesn't want to leverage multiple contexts, it just passes 0 here for every request.</p><p>The proxy is configured to use a maximum number of attribute contexts in order to prevent an explosion of contexts in the mixer's memory space.</p></td>
 </tr>
<a name="istio.mixer.v1.Attributes.reset_context"></a>
 <tr>
  <td><code>reset_context</code></td>
  <td>bool</td>
  <td><p>When true, resets the current attribute context to the empty state before applying any incoming attributes.</p><p>Resetting contexts is useful to constrain the amount of resources used by the mixer. The proxy needs to intelligently manage a pool of contexts. It may be useful to reset a context when certain big events happen, such as when an HTTP2 connection into the proxy terminates.</p></td>
 </tr>
<a name="istio.mixer.v1.Attributes.string_attributes"></a>
 <tr>
  <td><code>string_attributes</code></td>
  <td>repeated map&lt;int32, string&gt;</td>
  <td>Attributes being updated within the specified attribute context. These maps add and/or overwrite the context's current set of attributes.</td>
 </tr>
<a name="istio.mixer.v1.Attributes.int64_attributes"></a>
 <tr>
  <td><code>int64_attributes</code></td>
  <td>repeated map&lt;int32, int64&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.double_attributes"></a>
 <tr>
  <td><code>double_attributes</code></td>
  <td>repeated map&lt;int32, double&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.bool_attributes"></a>
 <tr>
  <td><code>bool_attributes</code></td>
  <td>repeated map&lt;int32, bool&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.timestamp_attributes"></a>
 <tr>
  <td><code>timestamp_attributes</code></td>
  <td>repeated map&lt;int32, <a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#timestamp">Timestamp</a>&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.duration_attributes"></a>
 <tr>
  <td><code>duration_attributes</code></td>
  <td>repeated map&lt;int32, <a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a>&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.bytes_attributes"></a>
 <tr>
  <td><code>bytes_attributes</code></td>
  <td>repeated map&lt;int32, bytes&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.stringMap_attributes"></a>
 <tr>
  <td><code>stringMap_attributes</code></td>
  <td>repeated map&lt;int32, <a href="#istio.mixer.v1.StringMap">StringMap</a>&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.deleted_attributes"></a>
 <tr>
  <td><code>deleted_attributes[]</code></td>
  <td>repeated int32</td>
  <td>Attributes that should be removed from the specified attribute context. Deleting attributes which aren't currently in the attribute context is not considered an error.</td>
 </tr>
<a name="istio.mixer.v1.Attributes.timestamp_attributes_HACK"></a>
 <tr>
  <td><code>timestamp_attributes_HACK</code></td>
  <td>repeated map&lt;int32, <a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#timestamp">Timestamp</a>&gt;</td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.Attributes.duration_attributes_HACK"></a>
 <tr>
  <td><code>duration_attributes_HACK</code></td>
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
<a name="istio.mixer.v1.CheckRequest.request_index"></a>
 <tr>
  <td><code>request_index</code></td>
  <td>int64</td>
  <td>Index within the stream for this request, used to match to responses</td>
 </tr>
<a name="istio.mixer.v1.CheckRequest.attribute_update"></a>
 <tr>
  <td><code>attribute_update</code></td>
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
<a name="istio.mixer.v1.CheckResponse.request_index"></a>
 <tr>
  <td><code>request_index</code></td>
  <td>int64</td>
  <td>Index of the request this response is associated with</td>
 </tr>
<a name="istio.mixer.v1.CheckResponse.attribute_update"></a>
 <tr>
  <td><code>attribute_update</code></td>
  <td><a href="#istio.mixer.v1.Attributes">Attributes</a></td>
  <td>The attributes to use for this response</td>
 </tr>
<a name="istio.mixer.v1.CheckResponse.result"></a>
 <tr>
  <td><code>result</code></td>
  <td><a href="#google.rpc.Status">Status</a></td>
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
<a name="istio.mixer.v1.QuotaRequest.request_index"></a>
 <tr>
  <td><code>request_index</code></td>
  <td>int64</td>
  <td>Index within the stream for this request, used to match to responses</td>
 </tr>
<a name="istio.mixer.v1.QuotaRequest.attribute_update"></a>
 <tr>
  <td><code>attribute_update</code></td>
  <td><a href="#istio.mixer.v1.Attributes">Attributes</a></td>
  <td>The attributes to use for this request</td>
 </tr>
<a name="istio.mixer.v1.QuotaRequest.deduplication_id"></a>
 <tr>
  <td><code>deduplication_id</code></td>
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
<a name="istio.mixer.v1.QuotaRequest.best_effort"></a>
 <tr>
  <td><code>best_effort</code></td>
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
<a name="istio.mixer.v1.QuotaResponse.request_index"></a>
 <tr>
  <td><code>request_index</code></td>
  <td>int64</td>
  <td>Index of the request this response is associated with.</td>
 </tr>
<a name="istio.mixer.v1.QuotaResponse.attribute_update"></a>
 <tr>
  <td><code>attribute_update</code></td>
  <td><a href="#istio.mixer.v1.Attributes">Attributes</a></td>
  <td>The attributes to use for this response</td>
 </tr>
<a name="istio.mixer.v1.QuotaResponse.result"></a>
 <tr>
  <td><code>result</code></td>
  <td><a href="#google.rpc.Status">Status</a></td>
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
<a name="istio.mixer.v1.ReportRequest.request_index"></a>
 <tr>
  <td><code>request_index</code></td>
  <td>int64</td>
  <td>Index within the stream for this request, used to match to responses</td>
 </tr>
<a name="istio.mixer.v1.ReportRequest.attribute_update"></a>
 <tr>
  <td><code>attribute_update</code></td>
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
<a name="istio.mixer.v1.ReportResponse.request_index"></a>
 <tr>
  <td><code>request_index</code></td>
  <td>int64</td>
  <td>Index of the request this response is associated with</td>
 </tr>
<a name="istio.mixer.v1.ReportResponse.attribute_update"></a>
 <tr>
  <td><code>attribute_update</code></td>
  <td><a href="#istio.mixer.v1.Attributes">Attributes</a></td>
  <td>The attributes to use for this response</td>
 </tr>
<a name="istio.mixer.v1.ReportResponse.result"></a>
 <tr>
  <td><code>result</code></td>
  <td><a href="#google.rpc.Status">Status</a></td>
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

<a name="rpc_google.rpc"></a>
## Package google.rpc

<a name="rpc_google.rpc_index"></a>
### Index

* [Status](#google.rpc.Status)
(message)

<a name="google.rpc.Status"></a>
### Status
The `Status` type defines a logical error model that is suitable for different
programming environments, including REST APIs and RPC APIs. It is used by
[gRPC](https://github.com/grpc). The error model is designed to be:

- Simple to use and understand for most users
- Flexible enough to meet unexpected needs



<a name="rpc_google.rpc_google.rpc.Status_description_subsection"></a>
#### Overview
The `Status` message contains three pieces of data: error code, error message,
and error details. The error code should be an enum value of
[google.rpc.Code](#google.rpc.Code), but it may accept additional error codes if needed.  The
error message should be a developer-facing English message that helps
developers *understand* and *resolve* the error. If a localized user-facing
error message is needed, put the localized message in the error details or
localize it in the client. The optional error details may contain arbitrary
information about the error. There is a predefined set of error detail types
in the package `google.rpc` which can be used for common error conditions.



<a name="rpc_google.rpc_google.rpc.Status_description_subsection_1"></a>
#### Language mapping
The `Status` message is the logical representation of the error model, but it
is not necessarily the actual wire format. When the `Status` message is
exposed in different client libraries and different wire protocols, it can be
mapped differently. For example, it will likely be mapped to some exceptions
in Java, but more likely mapped to some error codes in C.



<a name="rpc_google.rpc_google.rpc.Status_description_subsection_2"></a>
#### Other uses
The error model and the `Status` message can be used in a variety of
environments, either with or without APIs, to provide a
consistent developer experience across different environments.

Example uses of this error model include:

- Partial errors. If a service needs to return partial errors to the client,
    it may embed the `Status` in the normal response to indicate the partial
    errors.

- Workflow errors. A typical workflow has multiple steps. Each step may
    have a `Status` message for error reporting purpose.

- Batch operations. If a client uses batch request and batch response, the
    `Status` message should be used directly inside batch response, one for
    each error sub-response.

- Asynchronous operations. If an API call embeds asynchronous operation
    results in its response, the status of those operations should be
    represented directly using the `Status` message.

- Logging. If some API errors are stored in logs, the message `Status` could
    be used directly after any stripping needed for security/privacy reasons.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="google.rpc.Status.code"></a>
 <tr>
  <td><code>code</code></td>
  <td>int32</td>
  <td>The status code, which should be an enum value of <a href="#google.rpc.Code">google.rpc.Code</a>.</td>
 </tr>
<a name="google.rpc.Status.message"></a>
 <tr>
  <td><code>message</code></td>
  <td>string</td>
  <td>A developer-facing error message, which should be in English. Any user-facing error message should be localized and sent in the <a href="#google.rpc.Status.details">google.rpc.Status.details</a> field, or localized by the client.</td>
 </tr>
<a name="google.rpc.Status.details"></a>
 <tr>
  <td><code>details[]</code></td>
  <td>repeated <a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#any">Any</a></td>
  <td>A list of messages that carry the error details. There will be a common set of message types for APIs to use.</td>
 </tr>
</table>

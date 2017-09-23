---
title: stackdriver Config
overview: Generated documentation for Mixer's stackdriver Adapter Configuration Schema

order: 50

layout: docs
type: markdown
---


<a name="rpcAdapter.stackdriver.configIndex"></a>
### Index

* [Params](#adapter.stackdriver.config.Params)
(message)
* [Params.LogInfo](#adapter.stackdriver.config.Params.LogInfo)
(message)
* [Params.LogInfo.HttpRequestMapping](#adapter.stackdriver.config.Params.LogInfo.HttpRequestMapping)
(message)
* [Params.MetricInfo](#adapter.stackdriver.config.Params.MetricInfo)
(message)
* [Params.MetricInfo.BucketsDefinition](#adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition)
(message)
* [Params.MetricInfo.BucketsDefinition.Explicit](#adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Explicit)
(message)
* [Params.MetricInfo.BucketsDefinition.Exponential](#adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Exponential)
(message)
* [Params.MetricInfo.BucketsDefinition.Linear](#adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Linear)
(message)

<a name="adapter.stackdriver.config.Params"></a>
### Params

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.stackdriver.config.Params.endpoint"></a>
 <tr>
  <td><code>endpoint</code></td>
  <td>string</td>
  <td>Endpoint URL to send stackdriver data - leave empty to use the StackDriver SDK's default value (monitoring.googleapis.com).</td>
 </tr>
<a name="adapter.stackdriver.config.Params.projectId"></a>
 <tr>
  <td><code>projectId</code></td>
  <td>string</td>
  <td>GCP Project to attach metrics to.</td>
 </tr>
<a name="adapter.stackdriver.config.Params.pushInterval"></a>
 <tr>
  <td><code>pushInterval</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>This adapter batches the data it sends to Stackdriver; we will push to stackdriver every pushInterval. If no value is provided we default to once per minute.</td>
 </tr>
<a name="adapter.stackdriver.config.Params.metricInfo"></a>
 <tr>
  <td><code>metricInfo</code></td>
  <td>repeated map&lt;string, <a href="#adapter.stackdriver.config.Params.MetricInfo">MetricInfo</a>&gt;</td>
  <td>A map of Istio metric name to Stackdriver metric info.</td>
 </tr>
<a name="adapter.stackdriver.config.Params.logInfo"></a>
 <tr>
  <td><code>logInfo</code></td>
  <td>repeated map&lt;string, <a href="#adapter.stackdriver.config.Params.LogInfo">LogInfo</a>&gt;</td>
  <td>A map of Istio LogEntry name to Stackdriver log info.</td>
 </tr>
<a name="adapter.stackdriver.config.Params.appCredentials"></a>
 <tr>
  <td><code>appCredentials</code></td>
  <td>bool (oneof )</td>
  <td><p>Use Google's Application Default Credentials to authorize calls made by the StackDriver SDK.</p><p><a href="https://developers.google.com/identity/protocols/application-default-credentials">See Google's documentation</a>.</p></td>
 </tr>
<a name="adapter.stackdriver.config.Params.apiKey"></a>
 <tr>
  <td><code>apiKey</code></td>
  <td>string (oneof )</td>
  <td>The API Key to be used for auth.</td>
 </tr>
<a name="adapter.stackdriver.config.Params.serviceAccountPath"></a>
 <tr>
  <td><code>serviceAccountPath</code></td>
  <td>string (oneof )</td>
  <td>The path to a Google service account credential file, relative to the Mixer. E.g. <code>/etc/opt/mixer/gcp-serviceaccount-creds.json</code> or <code>./testdata/my-test-account-creds.json</code>.</td>
 </tr>
</table>

<a name="adapter.stackdriver.config.Params.LogInfo"></a>
### LogInfo
Describes how to represent an Istio Log in Stackdriver.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.stackdriver.config.Params.LogInfo.labelNames"></a>
 <tr>
  <td><code>labelNames[]</code></td>
  <td>repeated string</td>
  <td>The logging template provides a set of variables; these list the subset of variables that should be used to form Stackdriver labels for the log entry.</td>
 </tr>
<a name="adapter.stackdriver.config.Params.LogInfo.payloadTemplate"></a>
 <tr>
  <td><code>payloadTemplate</code></td>
  <td>string</td>
  <td>A golang text/template template that will be executed to construct the payload for this log entry. It will be given the full set of variables for the log to use to construct its result.</td>
 </tr>
<a name="adapter.stackdriver.config.Params.LogInfo.httpMapping"></a>
 <tr>
  <td><code>httpMapping</code></td>
  <td><a href="#adapter.stackdriver.config.Params.LogInfo.HttpRequestMapping">HttpRequestMapping</a></td>
  <td>If an HttpRequestMapping is provided, a HttpRequest object will be filled out for this log entry using the variables named in the mapping to populate the fields of the request struct from the instance's variables.</td>
 </tr>
</table>

<a name="adapter.stackdriver.config.Params.LogInfo.HttpRequestMapping"></a>
### HttpRequestMapping
Maps from template variable names to the various fields of Stackdriver's HTTP request struct.
See https://godoc.org/cloud.google.com/go/logging#HTTPRequest

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.stackdriver.config.Params.LogInfo.HttpRequestMapping.status"></a>
 <tr>
  <td><code>status</code></td>
  <td>string</td>
  <td>template variable name to map into HTTPRequest.Status</td>
 </tr>
<a name="adapter.stackdriver.config.Params.LogInfo.HttpRequestMapping.requestSize"></a>
 <tr>
  <td><code>requestSize</code></td>
  <td>string</td>
  <td>template variable name to map into HTTPRequest.RequestSize</td>
 </tr>
<a name="adapter.stackdriver.config.Params.LogInfo.HttpRequestMapping.responseSize"></a>
 <tr>
  <td><code>responseSize</code></td>
  <td>string</td>
  <td>template variable name to map into HTTPRequest.ResponseSize</td>
 </tr>
<a name="adapter.stackdriver.config.Params.LogInfo.HttpRequestMapping.latency"></a>
 <tr>
  <td><code>latency</code></td>
  <td>string</td>
  <td>template variable name to map into HTTPRequest.Latency</td>
 </tr>
<a name="adapter.stackdriver.config.Params.LogInfo.HttpRequestMapping.localIp"></a>
 <tr>
  <td><code>localIp</code></td>
  <td>string</td>
  <td>template variable name to map into HTTPRequest.LocalIP</td>
 </tr>
<a name="adapter.stackdriver.config.Params.LogInfo.HttpRequestMapping.remoteIp"></a>
 <tr>
  <td><code>remoteIp</code></td>
  <td>string</td>
  <td>template variable name to map into HTTPRequest.RemoteIP</td>
 </tr>
</table>

<a name="adapter.stackdriver.config.Params.MetricInfo"></a>
### MetricInfo
Describes how to represent an Istio metric in Stackdriver.
See https://github.com/googleapis/googleapis/blob/master/google/api/metric.proto

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.stackdriver.config.Params.MetricInfo.kind"></a>
 <tr>
  <td><code>kind</code></td>
  <td><a href="#google.api.MetricDescriptor.MetricKind">MetricKind</a></td>
  <td></td>
 </tr>
<a name="adapter.stackdriver.config.Params.MetricInfo.value"></a>
 <tr>
  <td><code>value</code></td>
  <td><a href="#google.api.MetricDescriptor.ValueType">ValueType</a></td>
  <td></td>
 </tr>
<a name="adapter.stackdriver.config.Params.MetricInfo.buckets"></a>
 <tr>
  <td><code>buckets</code></td>
  <td><a href="#adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition">BucketsDefinition</a></td>
  <td>For metrics with a metric value of DISTRIBUTION, this provides a mechanism for configuring the buckets that will be used to store the aggregated values. This field must be provided for metrics declared to be of type DISTRIBUTION. This field will be ignored for non-distribution metric kinds.</td>
 </tr>
</table>

<a name="adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition"></a>
### BucketsDefinition
Describes buckets for DISTRIBUTION valued metrics.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.linearBuckets"></a>
 <tr>
  <td><code>linearBuckets</code></td>
  <td><a href="#adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Linear">Linear</a> (oneof )</td>
  <td>The linear buckets.</td>
 </tr>
<a name="adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.exponentialBuckets"></a>
 <tr>
  <td><code>exponentialBuckets</code></td>
  <td><a href="#adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Exponential">Exponential</a> (oneof )</td>
  <td>The exponential buckets.</td>
 </tr>
<a name="adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.explicitBuckets"></a>
 <tr>
  <td><code>explicitBuckets</code></td>
  <td><a href="#adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Explicit">Explicit</a> (oneof )</td>
  <td>The explicit buckets.</td>
 </tr>
</table>

<a name="adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Explicit"></a>
### Explicit
Specifies a set of buckets with arbitrary widths.

There are `size(bounds) + 1` (= `N`) buckets. Bucket `i` has the following
boundaries:

* Upper bound (`0 <= i < N-1`): `bounds[i]`
* Lower bound (`1 <= i < N`): `bounds[i - 1]`

The `bounds` field must contain at least one element. If `bounds` has
only one element, then there are no finite buckets, and that single
element is the common boundary of the overflow and underflow buckets.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Explicit.bounds"></a>
 <tr>
  <td><code>bounds[]</code></td>
  <td>repeated double</td>
  <td>The values must be monotonically increasing.</td>
 </tr>
</table>

<a name="adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Exponential"></a>
### Exponential
Specifies an exponential sequence of buckets that have a width that is
proportional to the value of the lower bound. Each bucket represents a
constant relative uncertainty on a specific value in the bucket.

There are `numFiniteBuckets + 2` (= `N`) buckets. The two additional
buckets are the underflow and overflow buckets.

Bucket `i` has the following boundaries:

* Upper bound (0 <= i < N-1): `scale * (growthFactor ^ i)`
* Lower bound (1 <= i < N): `scale * (growthFactor ^ (i - 1))`

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Exponential.numFiniteBuckets"></a>
 <tr>
  <td><code>numFiniteBuckets</code></td>
  <td>int32</td>
  <td>Must be greater than 0.</td>
 </tr>
<a name="adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Exponential.growthFactor"></a>
 <tr>
  <td><code>growthFactor</code></td>
  <td>double</td>
  <td>Must be greater than 1.</td>
 </tr>
<a name="adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Exponential.scale"></a>
 <tr>
  <td><code>scale</code></td>
  <td>double</td>
  <td>Must be greater than 0.</td>
 </tr>
</table>

<a name="adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Linear"></a>
### Linear
Specifies a linear sequence of buckets that all have the same width
(except overflow and underflow). Each bucket represents a constant
absolute uncertainty on the specific value in the bucket.

There are `numFiniteBuckets + 2` (= `N`) buckets. The two additional
buckets are the underflow and overflow buckets.

Bucket `i` has the following boundaries:

* Upper bound (`0 <= i < N-1`): `offset + (width * i)`
* Lower bound (`1 <= i < N`): `offset + (width * (i - 1))`

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Linear.numFiniteBuckets"></a>
 <tr>
  <td><code>numFiniteBuckets</code></td>
  <td>int32</td>
  <td>Must be greater than 0.</td>
 </tr>
<a name="adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Linear.width"></a>
 <tr>
  <td><code>width</code></td>
  <td>double</td>
  <td>Must be greater than 0.</td>
 </tr>
<a name="adapter.stackdriver.config.Params.MetricInfo.BucketsDefinition.Linear.offset"></a>
 <tr>
  <td><code>offset</code></td>
  <td>double</td>
  <td>Lower bound of the first bucket.</td>
 </tr>
</table>

<a name="rpcGoogle.api"></a>
## Package google.api

<a name="rpcGoogle.apiIndex"></a>
### Index

* [MetricDescriptor](#google.api.MetricDescriptor)
(message)
* [MetricDescriptor.MetricKind](#google.api.MetricDescriptor.MetricKind)
(enum)
* [MetricDescriptor.ValueType](#google.api.MetricDescriptor.ValueType)
(enum)

<a name="google.api.MetricDescriptor"></a>
### MetricDescriptor
Defines a metric type and its schema. Once a metric descriptor is created,
deleting or altering it stops data collection and makes the metric type's
existing data unusable.

NOTE: _No fields in this message type.__

<a name="google.api.MetricDescriptor.MetricKind"></a>
### MetricKind
The kind of measurement. It describes how the data is reported.


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="google.api.MetricDescriptor.MetricKind.METRICKINDUNSPECIFIED"></a>
 <tr>
  <td>METRICKINDUNSPECIFIED</td>
  <td>Do not use this default value.</td>
 </tr>
<a name="google.api.MetricDescriptor.MetricKind.GAUGE"></a>
 <tr>
  <td>GAUGE</td>
  <td>An instantaneous measurement of a value.</td>
 </tr>
<a name="google.api.MetricDescriptor.MetricKind.DELTA"></a>
 <tr>
  <td>DELTA</td>
  <td>The change in a value during a time interval.</td>
 </tr>
<a name="google.api.MetricDescriptor.MetricKind.CUMULATIVE"></a>
 <tr>
  <td>CUMULATIVE</td>
  <td>A value accumulated over a time interval. Cumulative measurements in a time series should have the same start time and increasing end times, until an event resets the cumulative value to zero and sets a new start time for the following points.</td>
 </tr>
</table>

<a name="google.api.MetricDescriptor.ValueType"></a>
### ValueType
The value type of a metric.


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="google.api.MetricDescriptor.ValueType.VALUETYPEUNSPECIFIED"></a>
 <tr>
  <td>VALUETYPEUNSPECIFIED</td>
  <td>Do not use this default value.</td>
 </tr>
<a name="google.api.MetricDescriptor.ValueType.BOOL"></a>
 <tr>
  <td>BOOL</td>
  <td>The value is a boolean. This value type can be used only if the metric kind is <code>GAUGE</code>.</td>
 </tr>
<a name="google.api.MetricDescriptor.ValueType.INT64"></a>
 <tr>
  <td>INT64</td>
  <td>The value is a signed 64-bit integer.</td>
 </tr>
<a name="google.api.MetricDescriptor.ValueType.DOUBLE"></a>
 <tr>
  <td>DOUBLE</td>
  <td>The value is a double precision floating point number.</td>
 </tr>
<a name="google.api.MetricDescriptor.ValueType.STRING"></a>
 <tr>
  <td>STRING</td>
  <td>The value is a text string. This value type can be used only if the metric kind is <code>GAUGE</code>.</td>
 </tr>
<a name="google.api.MetricDescriptor.ValueType.DISTRIBUTION"></a>
 <tr>
  <td>DISTRIBUTION</td>
  <td>The value is a <code>Distribution</code>.</td>
 </tr>
<a name="google.api.MetricDescriptor.ValueType.MONEY"></a>
 <tr>
  <td>MONEY</td>
  <td>The value is money.</td>
 </tr>
</table>

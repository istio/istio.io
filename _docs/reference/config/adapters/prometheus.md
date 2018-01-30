---
title: prometheus Config
overview: Generated documentation for Mixer's prometheus Adapter Configuration Schema

order: 40

layout: docs
type: markdown
---


<a name="rpcAdapter.prometheus.configIndex"></a>
### Index

* [Params](#adapter.prometheus.config.Params)
(message)
* [Params.MetricInfo](#adapter.prometheus.config.Params.MetricInfo)
(message)
* [Params.MetricInfo.BucketsDefinition](#adapter.prometheus.config.Params.MetricInfo.BucketsDefinition)
(message)
* [Params.MetricInfo.BucketsDefinition.Explicit](#adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Explicit)
(message)
* [Params.MetricInfo.BucketsDefinition.Exponential](#adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Exponential)
(message)
* [Params.MetricInfo.BucketsDefinition.Linear](#adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Linear)
(message)
* [Params.MetricInfo.Kind](#adapter.prometheus.config.Params.MetricInfo.Kind)
(enum)

<a name="adapter.prometheus.config.Params"></a>
### Params

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.prometheus.config.Params.metrics"></a>
 <tr>
  <td><code>metrics[]</code></td>
  <td>repeated <a href="#adapter.prometheus.config.Params.MetricInfo">MetricInfo</a></td>
  <td>The set of metrics to represent in Prometheus. If a metric is defined in Istio but doesn't have a corresponding shape here, it will not be populated at runtime.</td>
 </tr>
</table>

<a name="adapter.prometheus.config.Params.MetricInfo"></a>
### MetricInfo
Describes how a metric should be represented in Prometheus.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.name"></a>
 <tr>
  <td><code>name</code></td>
  <td>string</td>
  <td>Recommended. The name is used to register the prometheus metric. It must be unique across all prometheus metrics as prometheus does not allow duplicate names. If name is not specified a sanitized version of instanceName is used.</td>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.instanceName"></a>
 <tr>
  <td><code>instanceName</code></td>
  <td>string</td>
  <td>Required. The name is the fully qualified name of the Istio metric instance that this MetricInfo processes.</td>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.description"></a>
 <tr>
  <td><code>description</code></td>
  <td>string</td>
  <td>Optional. A human readable description of this metric.</td>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.kind"></a>
 <tr>
  <td><code>kind</code></td>
  <td><a href="#adapter.prometheus.config.Params.MetricInfo.Kind">Kind</a></td>
  <td></td>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.buckets"></a>
 <tr>
  <td><code>buckets</code></td>
  <td><a href="#adapter.prometheus.config.Params.MetricInfo.BucketsDefinition">BucketsDefinition</a></td>
  <td>For metrics with a metric kind of DISTRIBUTION, this provides a mechanism for configuring the buckets that will be used to store the aggregated values. This field must be provided for metrics declared to be of type DISTRIBUTION. This field will be ignored for non-distribution metric kinds.</td>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.labelNames"></a>
 <tr>
  <td><code>labelNames[]</code></td>
  <td>repeated string</td>
  <td>The names of labels to use: these need to match the dimensions of the Istio metric.</td>
 </tr>
</table>

<a name="adapter.prometheus.config.Params.MetricInfo.BucketsDefinition"></a>
### BucketsDefinition
Describes buckets for DISTRIBUTION kind metrics.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.linearBuckets"></a>
 <tr>
  <td><code>linearBuckets</code></td>
  <td><a href="#adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Linear">Linear</a> (oneof )</td>
  <td>The linear buckets.</td>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.exponentialBuckets"></a>
 <tr>
  <td><code>exponentialBuckets</code></td>
  <td><a href="#adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Exponential">Exponential</a> (oneof )</td>
  <td>The exponential buckets.</td>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.explicitBuckets"></a>
 <tr>
  <td><code>explicitBuckets</code></td>
  <td><a href="#adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Explicit">Explicit</a> (oneof )</td>
  <td>The explicit buckets.</td>
 </tr>
</table>

<a name="adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Explicit"></a>
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
<a name="adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Explicit.bounds"></a>
 <tr>
  <td><code>bounds[]</code></td>
  <td>repeated double</td>
  <td>The values must be monotonically increasing.</td>
 </tr>
</table>

<a name="adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Exponential"></a>
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
<a name="adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Exponential.numFiniteBuckets"></a>
 <tr>
  <td><code>numFiniteBuckets</code></td>
  <td>int32</td>
  <td>Must be greater than 0.</td>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Exponential.growthFactor"></a>
 <tr>
  <td><code>growthFactor</code></td>
  <td>double</td>
  <td>Must be greater than 1.</td>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Exponential.scale"></a>
 <tr>
  <td><code>scale</code></td>
  <td>double</td>
  <td>Must be greater than 0.</td>
 </tr>
</table>

<a name="adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Linear"></a>
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
<a name="adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Linear.numFiniteBuckets"></a>
 <tr>
  <td><code>numFiniteBuckets</code></td>
  <td>int32</td>
  <td>Must be greater than 0.</td>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Linear.width"></a>
 <tr>
  <td><code>width</code></td>
  <td>double</td>
  <td>Must be greater than 0.</td>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.BucketsDefinition.Linear.offset"></a>
 <tr>
  <td><code>offset</code></td>
  <td>double</td>
  <td>Lower bound of the first bucket.</td>
 </tr>
</table>

<a name="adapter.prometheus.config.Params.MetricInfo.Kind"></a>
### Kind
Describes what kind of metric this is.


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.Kind.UNSPECIFIED"></a>
 <tr>
  <td>UNSPECIFIED</td>
  <td></td>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.Kind.GAUGE"></a>
 <tr>
  <td>GAUGE</td>
  <td></td>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.Kind.COUNTER"></a>
 <tr>
  <td>COUNTER</td>
  <td></td>
 </tr>
<a name="adapter.prometheus.config.Params.MetricInfo.Kind.DISTRIBUTION"></a>
 <tr>
  <td>DISTRIBUTION</td>
  <td></td>
 </tr>
</table>

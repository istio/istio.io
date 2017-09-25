---
title: metric Config
overview: Generated documentation for Mixer's Template Configuration Schema

order: 1180

layout: docs
type: markdown
---


<a name="rpcIstio.mixer.v1.config.descriptorIndex"></a>
### Index

* [ValueType](#istio.mixer.v1.config.descriptor.ValueType)
(enum)

<a name="istio.mixer.v1.config.descriptor.ValueType"></a>
### ValueType
ValueType describes the types that values in the Istio system can take. These
are used to describe the type of Attributes at run time, describe the type of
the result of evaluating an expression, and to describe the runtime type of
fields of other descriptors.


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.VALUETYPEUNSPECIFIED"></a>
 <tr>
  <td>VALUETYPEUNSPECIFIED</td>
  <td>Invalid, default value.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.STRING"></a>
 <tr>
  <td>STRING</td>
  <td>An undiscriminated variable-length string.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.INT64"></a>
 <tr>
  <td>INT64</td>
  <td>An undiscriminated 64-bit signed integer.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.DOUBLE"></a>
 <tr>
  <td>DOUBLE</td>
  <td>An undiscriminated 64-bit floating-point value.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.BOOL"></a>
 <tr>
  <td>BOOL</td>
  <td>An undiscriminated boolean value.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.TIMESTAMP"></a>
 <tr>
  <td>TIMESTAMP</td>
  <td>A point in time.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.IPADDRESS"></a>
 <tr>
  <td>IPADDRESS</td>
  <td>An IP address.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.EMAILADDRESS"></a>
 <tr>
  <td>EMAILADDRESS</td>
  <td>An email address.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.URI"></a>
 <tr>
  <td>URI</td>
  <td>A URI.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.DNSNAME"></a>
 <tr>
  <td>DNSNAME</td>
  <td>A DNS name.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.DURATION"></a>
 <tr>
  <td>DURATION</td>
  <td>A span between two points in time.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.STRINGMAP"></a>
 <tr>
  <td>STRINGMAP</td>
  <td>A map string -&gt; string, typically used by headers.</td>
 </tr>
</table>

<a name="rpcMetric"></a>
## Package metric

<a name="rpcMetricIndex"></a>
### Index

* [Template](#metric.Template)
(message)

<a name="metric.Template"></a>
### Template
Metric represents a single piece of data to report.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="metric.Template.value"></a>
 <tr>
  <td><code>value</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.ValueType">ValueType</a></td>
  <td>The value being reported.</td>
 </tr>
<a name="metric.Template.dimensions"></a>
 <tr>
  <td><code>dimensions</code></td>
  <td>repeated map&lt;string, <a href="#istio.mixer.v1.config.descriptor.ValueType">ValueType</a>&gt;</td>
  <td>The unique identity of the particular metric to report.</td>
 </tr>
<a name="metric.Template.monitoredResourceType"></a>
 <tr>
  <td><code>monitoredResourceType</code></td>
  <td>string</td>
  <td>Optional. An expression to compute the type of the monitored resource this metric is being reported on. If the metric backend supports monitored resources, these fields are used to populate that resource. Otherwise these fields will be ignored by the adapter.</td>
 </tr>
<a name="metric.Template.monitoredResourceDimensions"></a>
 <tr>
  <td><code>monitoredResourceDimensions</code></td>
  <td>repeated map&lt;string, <a href="#istio.mixer.v1.config.descriptor.ValueType">ValueType</a>&gt;</td>
  <td>Optional. A set of expressions that will form the dimensions of the monitored resource this metric is being reported on. If the metric backend supports monitored resources, these fields are used to populate that resource. Otherwise these fields will be ignored by the adapter.</td>
 </tr>
</table>

---
title: metric Config
overview: Generated documentation for Mixer's Template Configuration Schema

order: 1180

layout: docs
type: markdown
---
{% include home.html %}

<a name="rpcMetric"></a>
## Package metric

<a name="rpcMetricIndex"></a>
### Index

* [Template](#metric.Template)
(message)

<a name="metric.Template"></a>
### Template
Metric represents a single piece of data to report.

When writing the configuration, the value for the fields associated with this template can either be a
literal or an [expression]({{home}}/docs/reference/config/mixer/expression-language.html). Please note that if the datatype of a field is not istio.mixer.v1.config.descriptor.ValueType,
then the expression's [inferred type]({{home}}/docs/reference/config/mixer/expression-language.html#type-checking) must match the datatype of the field.

Example config:

```
apiVersion: "config.istio.io/v1alpha2"
kind: metric
metadata:
  name: requestsize
  namespace: istio-config-default
spec:
  value: request.size | 0
  dimensions:
    sourceService: source.service | "unknown"
    sourceVersion: source.labels["version"] | "unknown"
    destinationService: destination.service | "unknown"
    destinationVersion: destination.labels["version"] | "unknown"
    responseCode: response.code | 200
  monitoredResourceType: '"UNSPECIFIED"'
```

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="metric.Template.value"></a>
 <tr>
  <td><code>value</code></td>
  <td><a href="{{home}}/docs/reference/config/mixer/value-type.html#istio.mixer.v1.config.descriptor.ValueType">ValueType</a></td>
  <td>The value being reported.</td>
 </tr>
<a name="metric.Template.dimensions"></a>
 <tr>
  <td><code>dimensions</code></td>
  <td>repeated map&lt;string, <a href="{{home}}/docs/reference/config/mixer/value-type.html#istio.mixer.v1.config.descriptor.ValueType">ValueType</a>&gt;</td>
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
  <td>repeated map&lt;string, <a href="{{home}}/docs/reference/config/mixer/value-type.html#istio.mixer.v1.config.descriptor.ValueType">ValueType</a>&gt;</td>
  <td>Optional. A set of expressions that will form the dimensions of the monitored resource this metric is being reported on. If the metric backend supports monitored resources, these fields are used to populate that resource. Otherwise these fields will be ignored by the adapter.</td>
 </tr>
</table>

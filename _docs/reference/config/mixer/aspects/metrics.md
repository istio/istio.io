---
title: metrics
overview: Generated documentation for Mixer's Aspect Configuration Schema

order: 1170

layout: docs
type: markdown
---


<a name="rpcAspect.Index"></a>
### Index

* [MetricsParams](#aspect.MetricsParams)
(message)
* [MetricsParams.Metric](#aspect.MetricsParams.Metric)
(message)

<a name="aspect.MetricsParams"></a>
### MetricsParams
Configures a metric aspect.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="aspect.MetricsParams.metrics"></a>
 <tr>
  <td><code>metrics[]</code></td>
  <td>repeated <a href="#aspect.MetricsParams.Metric">Metric</a></td>
  <td>The set of metrics that will be populated and handed to aspects at run time.</td>
 </tr>
</table>

<a name="aspect.MetricsParams.Metric"></a>
### Metric
Describes how attributes must be evaluated to produce values for the named metric. Suppose the following
MetricDescriptor exists in the global configuration:

```yaml
metricDescriptor:
  name: "responseCode"
  kind: COUNTER
  value: I64
  labels:
    name: apiMethod
    valueType: STRING
  labels:
    name: responseCode
    valueType: I64
```

To actually report metrics at run time a mapping from attributes to a metric's labels must be provided in
the form of a metric:

```yaml
metric:
  descriptorName: "responseCode" # must match metricDescriptor.name
  value: $requestCount        # Istio expression syntax for the attribute named "requestCount"
  labels:
    # either the attribute named 'apiMethod' or the literal string 'unknown'; must eval to a string
    apiMethod: $apiMethod | "unknown"
    # either the attribute named 'responseCode' or the literal int64 500; must eval to an int64
    responseCode: $responseCode | 500
```

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="aspect.MetricsParams.Metric.descriptorName"></a>
 <tr>
  <td><code>descriptorName</code></td>
  <td>string</td>
  <td>Must match the name of some metricDescriptor in the global config.</td>
 </tr>
<a name="aspect.MetricsParams.Metric.value"></a>
 <tr>
  <td><code>value</code></td>
  <td>string</td>
  <td>Attribute expression to evaluate to determine the value for this metric; the result of the evaluation must match the value ValueType of the metricDescriptor.</td>
 </tr>
<a name="aspect.MetricsParams.Metric.labels"></a>
 <tr>
  <td><code>labels</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td>Map of metricDescriptor label name to attribute expression. At run time each expression will be evaluated to determine the value provided to the aspect. The result of evaluating the expression must match the ValueType of the label in the metricDescriptor.</td>
 </tr>
</table>

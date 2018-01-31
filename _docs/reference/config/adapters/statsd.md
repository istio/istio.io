---
title: statsd Config
overview: Generated documentation for Mixer's statsd Adapter Configuration Schema

order: 60

layout: docs
type: markdown
---


<a name="rpcAdapter.statsd.configIndex"></a>
### Index

* [Params](#adapter.statsd.config.Params)
(message)
* [Params.MetricInfo](#adapter.statsd.config.Params.MetricInfo)
(message)
* [Params.MetricInfo.Type](#adapter.statsd.config.Params.MetricInfo.Type)
(enum)

<a name="adapter.statsd.config.Params"></a>
### Params

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.statsd.config.Params.address"></a>
 <tr>
  <td><code>address</code></td>
  <td>string</td>
  <td>Address of the statsd server, e.g. localhost:8125</td>
 </tr>
<a name="adapter.statsd.config.Params.prefix"></a>
 <tr>
  <td><code>prefix</code></td>
  <td>string</td>
  <td>Metric prefix, do not specify for no prefix</td>
 </tr>
<a name="adapter.statsd.config.Params.flushDuration"></a>
 <tr>
  <td><code>flushDuration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>FlushDuration controls the maximum amount of time between sending metrics to the statsd collection server. Metrics are reported when either flushBytes is full or flushDuration time has elapsed since the last report.</td>
 </tr>
<a name="adapter.statsd.config.Params.flushBytes"></a>
 <tr>
  <td><code>flushBytes</code></td>
  <td>int32</td>
  <td>Maximum UDP packet size to send; if not specified defaults to 512 bytes. If the statsd server is running on the same (private) network 1432 bytes is recommended for better performance.</td>
 </tr>
<a name="adapter.statsd.config.Params.samplingRate"></a>
 <tr>
  <td><code>samplingRate</code></td>
  <td>float</td>
  <td>Chance that any particular metric is sampled when incremented; can take the range [0, 1], defaults to 1 if unspecified.</td>
 </tr>
<a name="adapter.statsd.config.Params.metrics"></a>
 <tr>
  <td><code>metrics</code></td>
  <td>repeated map&lt;string, <a href="#adapter.statsd.config.Params.MetricInfo">MetricInfo</a>&gt;</td>
  <td>Map of metric name -&gt; info. If a metric's name is not in the map then the metric will not be exported to statsd.</td>
 </tr>
</table>

<a name="adapter.statsd.config.Params.MetricInfo"></a>
### MetricInfo
Describes how to represent this metric in statsd

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.statsd.config.Params.MetricInfo.type"></a>
 <tr>
  <td><code>type</code></td>
  <td><a href="#adapter.statsd.config.Params.MetricInfo.Type">Type</a></td>
  <td></td>
 </tr>
<a name="adapter.statsd.config.Params.MetricInfo.nameTemplate"></a>
 <tr>
  <td><code>nameTemplate</code></td>
  <td>string</td>
  <td><p>The template will be filled with values from the metric's labels and the resulting string will be used as the statsd metric name. This allows easier creation of statsd metrics like <code>actionName-responseCode</code>. The template strings must conform to go's text/template syntax. For the example of <code>actionName-responseCode</code>, we use the template:  <code>\{\{.apiMethod\}\}-\{\{.responseCode\}\}</code></p><p>If nameTemplate is the empty string the Istio metric name will be used for statsd metric's name.</p></td>
 </tr>
</table>

<a name="adapter.statsd.config.Params.MetricInfo.Type"></a>
### Type
The type of metric.


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="adapter.statsd.config.Params.MetricInfo.Type.UNKNOWN"></a>
 <tr>
  <td>UNKNOWN</td>
  <td></td>
 </tr>
<a name="adapter.statsd.config.Params.MetricInfo.Type.COUNTER"></a>
 <tr>
  <td>COUNTER</td>
  <td></td>
 </tr>
<a name="adapter.statsd.config.Params.MetricInfo.Type.GAUGE"></a>
 <tr>
  <td>GAUGE</td>
  <td></td>
 </tr>
<a name="adapter.statsd.config.Params.MetricInfo.Type.DISTRIBUTION"></a>
 <tr>
  <td>DISTRIBUTION</td>
  <td></td>
 </tr>
</table>

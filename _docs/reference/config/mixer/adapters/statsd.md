---
title: statsd
overview: Generated documentation for Mixer's statsd Adapter Configuration Schema

order: 70

layout: docs
type: markdown
---


<a name="rpcAdapter.statsd.Index"></a>
### Index

* [Params](#adapter.statsd.Params)
(message)

<a name="adapter.statsd.Params"></a>
### Params

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.statsd.Params.address"></a>
 <tr>
  <td><code>address</code></td>
  <td>string</td>
  <td>Address of the statsd server, e.g. localhost:8125</td>
 </tr>
<a name="adapter.statsd.Params.prefix"></a>
 <tr>
  <td><code>prefix</code></td>
  <td>string</td>
  <td>Metric prefix, do not specify for no prefix</td>
 </tr>
<a name="adapter.statsd.Params.flushDuration"></a>
 <tr>
  <td><code>flushDuration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Flush Interval controls the maximum amount of time between sending metrics to the statsd collection server. Metrics are reported when either flushBytes is full or flushInterval time has elapsed since the last report.</td>
 </tr>
<a name="adapter.statsd.Params.flushBytes"></a>
 <tr>
  <td><code>flushBytes</code></td>
  <td>int32</td>
  <td>Maximum UDP packet size to send; if not specified defaults to 512 bytes. If the statsd server is running on the same (private) network 1432 bytes is recommended for better performance.</td>
 </tr>
<a name="adapter.statsd.Params.samplingRate"></a>
 <tr>
  <td><code>samplingRate</code></td>
  <td>float</td>
  <td>Chance that any particular metric is sampled when incremented; can take the range [0, 1], defaults to 1 if unspecified.</td>
 </tr>
<a name="adapter.statsd.Params.metricNameTemplateStrings"></a>
 <tr>
  <td><code>metricNameTemplateStrings</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td><p>Map of metric name -&gt; template string; the template will be filled with values from the metric's labels and the resulting string will be used as the statsd metric name. This allows easier creation of statsd metrics like <code>actionName-responseCode</code>. The template strings must conform to go's text/template syntax. For the example of <code>actionName-responseCode</code>, we use the template:  <code>\{\{.apiMethod\}\}-\{\{.responseCode\}\}</code></p><p>If a metric's name is not in the map then the exported statsd metric name will be exactly the metric's name.</p></td>
 </tr>
</table>

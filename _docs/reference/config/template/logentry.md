---
title: logentry Config
overview: Generated documentation for Mixer's Template Configuration Schema

order: 1170

layout: docs
type: markdown
---
{% include home.html %}

<a name="rpcLogentry"></a>
## Package logentry

<a name="rpcLogentryIndex"></a>
### Index

* [Template](#logentry.Template)
(message)

<a name="logentry.Template"></a>
### Template
LogEntry represents an individual entry within a log.

When writing the configuration, the value for the fields associated with this template can either be a
literal or an [expression]({{home}}/docs/reference/config/mixer/expression-language.html). Please note that if the datatype of a field is not istio.mixer.v1.config.descriptor.ValueType,
then the expression's [inferred type]({{home}}/docs/reference/config/mixer/expression-language.html#type-checking) must match the datatype of the field.

Example config:

```
apiVersion: "config.istio.io/v1alpha2"
kind: logentry
metadata:
  name: accesslog
  namespace: istio-config-default
spec:
  severity: '"Default"'
  timestamp: request.time
  variables:
    sourceIp: source.ip | ip("0.0.0.0")
    destinationIp: destination.ip | ip("0.0.0.0")
    sourceUser: source.user | ""
    method: request.method | ""
    url: request.path | ""
    protocol: request.scheme | "http"
    responseCode: response.code | 0
    responseSize: response.size | 0
    requestSize: request.size | 0
    latency: response.duration | "0ms"
  monitoredResourceType: '"UNSPECIFIED"'
```

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="logentry.Template.variables"></a>
 <tr>
  <td><code>variables</code></td>
  <td>repeated map&lt;string, <a href="{{home}}/docs/reference/config/mixer/istio.mixer.v1.config.descriptor.html#ValueType">ValueType</a>&gt;</td>
  <td>Variables that are delivered for each log entry.</td>
 </tr>
<a name="logentry.Template.timestamp"></a>
 <tr>
  <td><code>timestamp</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#timestamp">Timestamp</a></td>
  <td>Timestamp is the time value for the log entry</td>
 </tr>
<a name="logentry.Template.severity"></a>
 <tr>
  <td><code>severity</code></td>
  <td>string</td>
  <td>Severity indicates the importance of the log entry.</td>
 </tr>
<a name="logentry.Template.monitoredResourceType"></a>
 <tr>
  <td><code>monitoredResourceType</code></td>
  <td>string</td>
  <td>Optional. An expression to compute the type of the monitored resource this log entry is being recorded on. If the logging backend supports monitored resources, these fields are used to populate that resource. Otherwise these fields will be ignored by the adapter.</td>
 </tr>
<a name="logentry.Template.monitoredResourceDimensions"></a>
 <tr>
  <td><code>monitoredResourceDimensions</code></td>
  <td>repeated map&lt;string, <a href="{{home}}/docs/reference/config/mixer/istio.mixer.v1.config.descriptor.html#ValueType">ValueType</a>&gt;</td>
  <td>Optional. A set of expressions that will form the dimensions of the monitored resource this log entry is being recorded on. If the logging backend supports monitored resources, these fields are used to populate that resource. Otherwise these fields will be ignored by the adapter.</td>
 </tr>
</table>

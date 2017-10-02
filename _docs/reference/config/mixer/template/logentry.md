---
title: logentry Config
overview: Generated documentation for Mixer's Template Configuration Schema

order: 1170

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
literal or an [expression](https://istio.io/docs/reference/config/mixer/expression-language.html). Please note that if the datatype of a field is not istio.mixer.v1.config.descriptor.ValueType,
then the expression's [inferred type](https://istio.io/docs/reference/config/mixer/expression-language.html#type-checking) must match the datatype of the field.

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
  <td>repeated map&lt;string, <a href="#istio.mixer.v1.config.descriptor.ValueType">ValueType</a>&gt;</td>
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
  <td>repeated map&lt;string, <a href="#istio.mixer.v1.config.descriptor.ValueType">ValueType</a>&gt;</td>
  <td>Optional. A set of expressions that will form the dimensions of the monitored resource this log entry is being recorded on. If the logging backend supports monitored resources, these fields are used to populate that resource. Otherwise these fields will be ignored by the adapter.</td>
 </tr>
</table>

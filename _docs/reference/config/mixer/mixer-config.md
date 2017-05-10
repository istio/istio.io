---
title: Mixer
overview: Mixer's configuration schema

order: 1190

layout: docs
type: markdown
---


<a name="rpcIstio.mixer.v1.configIndex"></a>
### Index

* [Adapter](#istio.mixer.v1.config.Adapter)
(message)
* [Aspect](#istio.mixer.v1.config.Aspect)
(message)
* [AspectRule](#istio.mixer.v1.config.AspectRule)
(message)
* [AttributeManifest](#istio.mixer.v1.config.AttributeManifest)
(message)
* [AttributeManifest.AttributeInfo](#istio.mixer.v1.config.AttributeManifest.AttributeInfo)
(message)
* [DnsName](#istio.mixer.v1.config.DnsName)
(message)
* [EmailAddress](#istio.mixer.v1.config.EmailAddress)
(message)
* [GlobalConfig](#istio.mixer.v1.config.GlobalConfig)
(message)
<b>(deprecated)</b>
* [IpAddress](#istio.mixer.v1.config.IpAddress)
(message)
* [ServiceConfig](#istio.mixer.v1.config.ServiceConfig)
(message)
<b>(deprecated)</b>
* [Uri](#istio.mixer.v1.config.Uri)
(message)

<a name="istio.mixer.v1.config.Adapter"></a>
### Adapter
Adapter allows the operator to configure a specific adapter implementation.
Each adapter implementation defines its own `params` proto. Note that unlike
[Aspect](#istio.mixer.v1.config.Aspect), the type of `params` varies with `impl`
and not with `kind`.

In the following example we define a `metrics` adapter using the Mixer's prepackaged
prometheus adapter. This adapter doesn't require any parameters.


```yaml
kind: metrics
name: prometheus-adapter
impl: prometheus
params:
```

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.Adapter.name"></a>
 <tr>
  <td><code>name</code></td>
  <td>string</td>
  <td>Required, must be unique per <code>kind</code>. Used by <a href="#istio.mixer.v1.config.Aspect">Aspect</a> to refer to this adapter. The name "default" is special: when an Aspect does not specify a name, the Adapter named "default" of the same <code>kind</code> is used to execute the intention described by the <a href="#istio.mixer.v1.config.AspectRule">AspectRule</a>s.</td>
 </tr>
<a name="istio.mixer.v1.config.Adapter.kind"></a>
 <tr>
  <td><code>kind</code></td>
  <td>string</td>
  <td>Required. The aspect this implementation with these params will implement; a single adapter implementation may implement many aspects, but an <code>Adapter</code> entry is required per kind.</td>
 </tr>
<a name="istio.mixer.v1.config.Adapter.impl"></a>
 <tr>
  <td><code>impl</code></td>
  <td>string</td>
  <td>Required. The name of a specific adapter implementation. An adapter's implementation name is typically a constant in its code.</td>
 </tr>
<a name="istio.mixer.v1.config.Adapter.params"></a>
 <tr>
  <td><code>params</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#struct">Struct</a></td>
  <td>Optional, depends on adapter implementation. Struct representation of a proto defined by the implementation; this varies depending on <code>impl</code>.</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.Aspect"></a>
### Aspect
Aspect describes how an adapter is intended to operate in the context of the
rule it's embedded in. The value for `params` depends on the `kind` of this
aspect: each kind of aspect defines its own `params` proto.

The following example instructs Mixer to populate a metric named "responseTime"
that was declared to have three labels: srcConsumerId, targetResponseStatusCode,
and targetServiceName. For each label and the metric's `value` we provide
an expression over Istio's attributes. Mixer evaluates these expressions for
each request.


```yaml
kind: metrics
params:
  metrics:
  - descriptorName: responseTime # tie this metric to a descriptor of the same name
    value: response.time  # from the set of canonical attributes
    labels:
      srcConsumerId: source.user | source.uid
      targetResponseStatusCode: response.code
      targetServiceName: target.service
```

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.Aspect.kind"></a>
 <tr>
  <td><code>kind</code></td>
  <td>string</td>
  <td>Required. The kind of aspect this intent is targeting.</td>
 </tr>
<a name="istio.mixer.v1.config.Aspect.adapter"></a>
 <tr>
  <td><code>adapter</code></td>
  <td>string</td>
  <td>Optional. The name of the adapter this Aspect targets. If no name is provided, Mixer will use the adapter of the target kind named "default".</td>
 </tr>
<a name="istio.mixer.v1.config.Aspect.params"></a>
 <tr>
  <td><code>params</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#struct">Struct</a></td>
  <td>Required. Struct representation of a proto defined by each aspect kind.</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.AspectRule"></a>
### AspectRule
An AspectRule is a selector and a set of intentions to be executed when the
selector is `true`. The selectors of the this rule's child AspectRules are only
evaluated if this rule's selector is true.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.AspectRule.selector"></a>
 <tr>
  <td><code>selector</code></td>
  <td>string</td>
  <td><p>Required. Selector is an attribute based predicate. When Mixer receives a request it evaluates all selectors in scope and executes the rules for all selectors that evaluated to true.</p><p>A few example selectors:</p>
<ul>
  <li>an empty selector evaluates to <code>true</code></li>
  <li><code>true</code>, a boolean literal; a rule with this selector will always be executed</li>
  <li><code>target.service == ratings*</code> selects any request targeting a service whose name starts with "ratings"</li>
  <li><code>attr1 == &quot;20&quot; &amp;&amp; attr2 == &quot;30&quot;</code> logical AND, OR, and NOT are also available</li>
</ul></td>
 </tr>
<a name="istio.mixer.v1.config.AspectRule.aspects"></a>
 <tr>
  <td><code>aspects[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.config.Aspect">Aspect</a></td>
  <td>The aspects that apply when selector evaluates to <code>true</code>.</td>
 </tr>
<a name="istio.mixer.v1.config.AspectRule.rules"></a>
 <tr>
  <td><code>rules[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.config.AspectRule">AspectRule</a></td>
  <td>Nested aspect rules; their selectors are evaluated if this selector predicate evaluates to <code>true</code>.</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.AttributeManifest"></a>
### AttributeManifest
AttributeManifest describes a set of Attributes produced by some component
of an Istio deployment.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.AttributeManifest.revision"></a>
 <tr>
  <td><code>revision</code></td>
  <td>string</td>
  <td>Optional. The revision of this document. Assigned by server.</td>
 </tr>
<a name="istio.mixer.v1.config.AttributeManifest.name"></a>
 <tr>
  <td><code>name</code></td>
  <td>string</td>
  <td>Required. Name of the component producing these attributes. This can be the proxy (with the canonical name "istio-proxy") or the name of an <code>attributes</code> kind adapter in Mixer.</td>
 </tr>
<a name="istio.mixer.v1.config.AttributeManifest.attributes"></a>
 <tr>
  <td><code>attributes</code></td>
  <td>repeated map&lt;string, <a href="#istio.mixer.v1.config.AttributeManifest.AttributeInfo">AttributeInfo</a>&gt;</td>
  <td><p>The set of attributes this Istio component will be responsible for producing at runtime. We map from attribute name to the attribute's specification. The name of an attribute, which is how attributes are referred to in aspect configuration, must conform to:</p>
<pre><code>Name = IDENT { SEPARATOR IDENT };
</code></pre><p>Where <code>IDENT</code> must match the regular expression <code>a-z+</code> and <code>SEPARATOR</code> must match the regular expression <code>[\.-]</code>.</p><p>Attribute names must be unique within a single Istio deployment. The set of canonical attributes are described at <a href="https://istio.io/docs/reference/attribute-vocabulary.html">https://istio.io/docs/reference/attribute-vocabulary.html</a>. Attributes not in that list should be named with a component-specific suffix such as request.count-my.component</p></td>
 </tr>
</table>

<a name="istio.mixer.v1.config.AttributeManifest.AttributeInfo"></a>
### AttributeInfo
AttributeInfo describes the schema of an Istio `Attribute`.



<a name="rpcIstio.mixer.v1.configIstio.mixer.v1.config.AttributeManifest.AttributeInfoDescriptionSubsectionSubsection"></a>
#### Istio Attributes
Istio uses `attributes` to describe runtime activities of Istio services.
An Istio attribute carries a specific piece of information about an activity,
such as the error code of an API request, the latency of an API request, or the
original IP address of a TCP connection. The attributes are often generated
and consumed by different services. For example, a frontend service can
generate an authenticated user attribute and pass it to a backend service for
access control purpose.

To simplify the system and improve developer experience, Istio uses
shared attribute definitions across all components. For example, the same
authenticated user attribute will be used for logging, monitoring, analytics,
billing, access control, auditing. Many Istio components provide their
functionality by collecting, generating, and operating on attributes.
For example, the proxy collects the error code attribute, and the logging
stores it into a log.



<a name="rpcIstio.mixer.v1.configIstio.mixer.v1.config.AttributeManifest.AttributeInfoDescriptionSubsectionSubsection_1"></a>
#### Design
Each Istio attribute must conform to an `AttributeInfo` in an
`AttributeManifest` in the current Istio deployment at runtime. An
`AttributeInfo` is used to define an attribute's
metadata: the type of its value and a detailed description that explains
the semantics of the attribute type. Each attribute's name is globally unique;
in other words an attribute name can only appear once across all manifests.

The runtime presentation of an attribute is intentionally left out of this
specification, because passing attribute using JSON, XML, or Protocol Buffers
does not change the semantics of the attribute. Different implementations
can choose different representations based on their needs.



<a name="rpcIstio.mixer.v1.configIstio.mixer.v1.config.AttributeManifest.AttributeInfoDescriptionSubsectionSubsection_2"></a>
#### HTTP Mapping
Because many systems already have REST APIs, it makes sense to define a
standard HTTP mapping for Istio attributes that are compatible with typical
REST APIs. The design is to map one attribute to one HTTP header, the
attribute name and value becomes the HTTP header name and value. The actual
encoding scheme will be decided later.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.AttributeManifest.AttributeInfo.description"></a>
 <tr>
  <td><code>description</code></td>
  <td>string</td>
  <td>Optional. A human-readable description of the attribute's purpose.</td>
 </tr>
<a name="istio.mixer.v1.config.AttributeManifest.AttributeInfo.valueType"></a>
 <tr>
  <td><code>valueType</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.ValueType">ValueType</a></td>
  <td>Required. The type of data carried by this attribute.</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.DnsName"></a>
### DnsName
DnsName holds a valid domain name.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.DnsName.value"></a>
 <tr>
  <td><code>value</code></td>
  <td>string</td>
  <td></td>
 </tr>
</table>

<a name="istio.mixer.v1.config.EmailAddress"></a>
### EmailAddress
EmailAddress holds a properly formatted email address.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.EmailAddress.value"></a>
 <tr>
  <td><code>value</code></td>
  <td>string</td>
  <td></td>
 </tr>
</table>

<a name="istio.mixer.v1.config.GlobalConfig"></a>
### GlobalConfig

WARNING: GlobalConfig is deprecated, see the Config API's
swagger spec.

GlobalConfig defines configuration elements that are available for the rest
of the config. It is used to configure adapters and make them available in
AspectRules.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.GlobalConfig.revision"></a>
 <tr>
  <td><code>revision</code></td>
  <td>string</td>
  <td>Optional.</td>
 </tr>
<a name="istio.mixer.v1.config.GlobalConfig.adapters"></a>
 <tr>
  <td><code>adapters[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.config.Adapter">Adapter</a></td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.config.GlobalConfig.manifests"></a>
 <tr>
  <td><code>manifests[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.config.AttributeManifest">AttributeManifest</a></td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.config.GlobalConfig.logs"></a>
 <tr>
  <td><code>logs[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.config.descriptor.LogEntryDescriptor">LogEntryDescriptor</a></td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.config.GlobalConfig.metrics"></a>
 <tr>
  <td><code>metrics[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.config.descriptor.MetricDescriptor">MetricDescriptor</a></td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.config.GlobalConfig.monitoredResources"></a>
 <tr>
  <td><code>monitoredResources[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.config.descriptor.MonitoredResourceDescriptor">MonitoredResourceDescriptor</a></td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.config.GlobalConfig.principals"></a>
 <tr>
  <td><code>principals[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.config.descriptor.PrincipalDescriptor">PrincipalDescriptor</a></td>
  <td></td>
 </tr>
<a name="istio.mixer.v1.config.GlobalConfig.quotas"></a>
 <tr>
  <td><code>quotas[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.config.descriptor.QuotaDescriptor">QuotaDescriptor</a></td>
  <td></td>
 </tr>
</table>

<a name="istio.mixer.v1.config.IpAddress"></a>
### IpAddress
IpAddress holds an IPv4 or IPv6 address.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.IpAddress.value"></a>
 <tr>
  <td><code>value</code></td>
  <td>bytes</td>
  <td></td>
 </tr>
</table>

<a name="istio.mixer.v1.config.ServiceConfig"></a>
### ServiceConfig

WARNING: ServiceConfig is deprecated, see the Config API's
swagger spec.

Configures a set of services.

The following example configures a metric that will be recorded for all services:


```yaml
subject: "namespace:ns1"
revision: "1011"
rules:
- selector: target.service == "*"
  aspects:
  - kind: metrics
    params:
      metrics: # defines metric collection across the board.
      - descriptorName: responseTimeByStatusCode
        value: response.time
        labels:
          statusCode: response.code
```

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.ServiceConfig.subject"></a>
 <tr>
  <td><code>subject</code></td>
  <td>string</td>
  <td>Optional. Subject is unique for a config type. 2 config with the same subject will overwrite each other</td>
 </tr>
<a name="istio.mixer.v1.config.ServiceConfig.revision"></a>
 <tr>
  <td><code>revision</code></td>
  <td>string</td>
  <td>Optional. revision of this config. This is assigned by the server</td>
 </tr>
<a name="istio.mixer.v1.config.ServiceConfig.rules"></a>
 <tr>
  <td><code>rules[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.config.AspectRule">AspectRule</a></td>
  <td></td>
 </tr>
</table>

<a name="istio.mixer.v1.config.Uri"></a>
### Uri
Uri represents a properly formed URI.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.Uri.value"></a>
 <tr>
  <td><code>value</code></td>
  <td>string</td>
  <td></td>
 </tr>
</table>

<a name="rpcIstio.mixer.v1.configDescriptor"></a>
## Package istio.mixer.v1.config.descriptor

<a name="rpcIstio.mixer.v1.configDescriptorIndex"></a>
### Index

* [LogEntryDescriptor](#istio.mixer.v1.config.descriptor.LogEntryDescriptor)
(message)
* [LogEntryDescriptor.PayloadFormat](#istio.mixer.v1.config.descriptor.LogEntryDescriptor.PayloadFormat)
(enum)
* [MetricDescriptor](#istio.mixer.v1.config.descriptor.MetricDescriptor)
(message)
* [MetricDescriptor.BucketsDefinition](#istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition)
(message)
* [MetricDescriptor.BucketsDefinition.Explicit](#istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Explicit)
(message)
* [MetricDescriptor.BucketsDefinition.Exponential](#istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Exponential)
(message)
* [MetricDescriptor.BucketsDefinition.Linear](#istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Linear)
(message)
* [MetricDescriptor.MetricKind](#istio.mixer.v1.config.descriptor.MetricDescriptor.MetricKind)
(enum)
* [MonitoredResourceDescriptor](#istio.mixer.v1.config.descriptor.MonitoredResourceDescriptor)
(message)
* [PrincipalDescriptor](#istio.mixer.v1.config.descriptor.PrincipalDescriptor)
(message)
* [QuotaDescriptor](#istio.mixer.v1.config.descriptor.QuotaDescriptor)
(message)
* [ValueType](#istio.mixer.v1.config.descriptor.ValueType)
(enum)

<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor"></a>
### LogEntryDescriptor
Defines the format of a single log entry.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor.name"></a>
 <tr>
  <td><code>name</code></td>
  <td>string</td>
  <td>Required. The name of this descriptor.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor.displayName"></a>
 <tr>
  <td><code>displayName</code></td>
  <td>string</td>
  <td>Optional. A concise name for the log entry type, which can be displayed in user interfaces. Use sentence case without an ending period, for example "Request count".</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor.description"></a>
 <tr>
  <td><code>description</code></td>
  <td>string</td>
  <td>Optional. A description of the log entry type, which can be used in documentation.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor.payloadFormat"></a>
 <tr>
  <td><code>payloadFormat</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.LogEntryDescriptor.PayloadFormat">PayloadFormat</a></td>
  <td>Required. Format of the value of the payload attribute.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor.logTemplate"></a>
 <tr>
  <td><code>logTemplate</code></td>
  <td>string</td>
  <td><p>Required. The template that will be populated with labels at runtime to generate a log message; the labels describe the parameters for this template.</p><p>The template strings must conform to go's text/template syntax.</p></td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor.labels"></a>
 <tr>
  <td><code>labels</code></td>
  <td>repeated map&lt;string, <a href="#istio.mixer.v1.config.descriptor.ValueType">ValueType</a>&gt;</td>
  <td>Labels describe the parameters of this log's template string. The log definition allows the user to map attribute expressions to actual values for these labels at run time; the result of the evaluation must be of the type described by the kind for each label.</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor.PayloadFormat"></a>
### PayloadFormat
PayloadFormat details the currently supported logging payload formats.
TEXT is the default payload format.


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor.PayloadFormat.PAYLOADFORMATUNSPECIFIED"></a>
 <tr>
  <td>PAYLOADFORMATUNSPECIFIED</td>
  <td>Invalid, default value.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor.PayloadFormat.TEXT"></a>
 <tr>
  <td>TEXT</td>
  <td>Indicates a payload format of raw text.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor.PayloadFormat.JSON"></a>
 <tr>
  <td>JSON</td>
  <td>Indicates that the payload is a serialized JSON object.</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.descriptor.MetricDescriptor"></a>
### MetricDescriptor
Defines a metric type and its schema.

A metric is dimensioned by a set of labels whose values are derived at runtime
from attributes. A given metric holds a unique value for potentially any
combination of these dimensions.

The following is an example descriptor for a metric capturing the number of
RPCs served, dimensioned by the method being called and response code returned
by the server:


```yaml
metrics:
  name: "responseCode"
  kind: COUNTER
  value: INT64
  labels:
    apiMethod: STRING
    responseCode: INT64
```


To actually report metrics at run time a mapping from attributes to a metric's
labels must be provided. This is provided in the aspect config; using our above
descriptor we might describe the metric as:


```yaml
metric:
  descriptor: "responseCode" # must match metricDescriptor.name
  value: request.count # expression syntax for the attribute named "request.count"
  labels:
    # either the attribute named 'api.method' or the literal string 'unknown'; must eval to a string
    apiMethod: api.method | "unknown"
    # either the attribute named 'response.code' or the literal int64 500; must eval to an int64
    responseCode: response.code | 500
```

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.name"></a>
 <tr>
  <td><code>name</code></td>
  <td>string</td>
  <td>Required. The name of this descriptor. This is used to refer to this descriptor in other contexts.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.displayName"></a>
 <tr>
  <td><code>displayName</code></td>
  <td>string</td>
  <td>Optional. A concise name for the metric, which can be displayed in user interfaces. Use sentence case without an ending period, for example "Request count".</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.description"></a>
 <tr>
  <td><code>description</code></td>
  <td>string</td>
  <td>Optional. A description of the metric, which should be used as the documentation for the metric.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.kind"></a>
 <tr>
  <td><code>kind</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.MetricDescriptor.MetricKind">MetricKind</a></td>
  <td>Required. Whether the metric records instantaneous values, changes to a value, etc.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.value"></a>
 <tr>
  <td><code>value</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.ValueType">ValueType</a></td>
  <td>Required. The type of data this metric records.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.labels"></a>
 <tr>
  <td><code>labels</code></td>
  <td>repeated map&lt;string, <a href="#istio.mixer.v1.config.descriptor.ValueType">ValueType</a>&gt;</td>
  <td>Labels that dimension the data recorded by this metric. The metric definition allows the user to map attribute expressions to actual values for these labels at run time; the result of the evaluation must be of the type described by the kind for each label.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.buckets"></a>
 <tr>
  <td><code>buckets</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition">BucketsDefinition</a></td>
  <td>For metrics with a metric kind of DISTRIBUTION, this provides a mechanism for configuring the buckets that will be used to store the aggregated values. This field must be provided for metrics declared to be of type DISTRIBUTION. This field will be ignored for non-distribution metric kinds.</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition"></a>
### BucketsDefinition

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.linearBuckets"></a>
 <tr>
  <td><code>linearBuckets</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Linear">Linear</a> (oneof )</td>
  <td>The linear buckets.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.exponentialBuckets"></a>
 <tr>
  <td><code>exponentialBuckets</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Exponential">Exponential</a> (oneof )</td>
  <td>The exponential buckets.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.explicitBuckets"></a>
 <tr>
  <td><code>explicitBuckets</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Explicit">Explicit</a> (oneof )</td>
  <td>The explicit buckets.</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Explicit"></a>
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
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Explicit.bounds"></a>
 <tr>
  <td><code>bounds[]</code></td>
  <td>repeated double</td>
  <td>The values must be monotonically increasing.</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Exponential"></a>
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
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Exponential.numFiniteBuckets"></a>
 <tr>
  <td><code>numFiniteBuckets</code></td>
  <td>int32</td>
  <td>Must be greater than 0.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Exponential.growthFactor"></a>
 <tr>
  <td><code>growthFactor</code></td>
  <td>double</td>
  <td>Must be greater than 1.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Exponential.scale"></a>
 <tr>
  <td><code>scale</code></td>
  <td>double</td>
  <td>Must be greater than 0.</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Linear"></a>
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
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Linear.numFiniteBuckets"></a>
 <tr>
  <td><code>numFiniteBuckets</code></td>
  <td>int32</td>
  <td>Must be greater than 0.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Linear.width"></a>
 <tr>
  <td><code>width</code></td>
  <td>double</td>
  <td>Must be greater than 0.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Linear.offset"></a>
 <tr>
  <td><code>offset</code></td>
  <td>double</td>
  <td>Lower bound of the first bucket.</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.MetricKind"></a>
### MetricKind
The kind of measurement. It describes how the data is recorded.


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.MetricKind.METRICKINDUNSPECIFIED"></a>
 <tr>
  <td>METRICKINDUNSPECIFIED</td>
  <td>Do not use this default value.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.MetricKind.GAUGE"></a>
 <tr>
  <td>GAUGE</td>
  <td>An instantaneous measurement of a value. For example, the number of VMs.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.MetricKind.COUNTER"></a>
 <tr>
  <td>COUNTER</td>
  <td>A count of occurrences over an interval, always a positive integer. For example, the number of API requests.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.MetricKind.DISTRIBUTION"></a>
 <tr>
  <td>DISTRIBUTION</td>
  <td><p>Summary statistics for a population of values. At the moment, only histograms representing the distribution of those values across a set of buckets are supported (configured via the buckets field).</p><p>Values for DISTRIBUTIONs will be reported in singular form. It will be up to the mixer adapters and backend systems to transform single reported values into the distribution form as needed (and as supported).</p></td>
 </tr>
</table>

<a name="istio.mixer.v1.config.descriptor.MonitoredResourceDescriptor"></a>
### MonitoredResourceDescriptor
An object that describes the schema of a `MonitoredResource`. A
`MonitoredResource` is used to define a type of resources for
monitoring purpose. For example, the monitored resource "VM" refers
to virtual machines, which requires 3 attributes "owner", "zone",
"name" to uniquely identify a specific instance. When reporting
a metric against a monitored resource, the metric attributes will
be used to associate the right value with the right instance,
such as memory usage of a VM.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MonitoredResourceDescriptor.name"></a>
 <tr>
  <td><code>name</code></td>
  <td>string</td>
  <td>Required. The name of this descriptor.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MonitoredResourceDescriptor.description"></a>
 <tr>
  <td><code>description</code></td>
  <td>string</td>
  <td>Optional. A detailed description of the monitored resource descriptor that might be used in documentation.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MonitoredResourceDescriptor.labels"></a>
 <tr>
  <td><code>labels</code></td>
  <td>repeated map&lt;string, <a href="#istio.mixer.v1.config.descriptor.ValueType">ValueType</a>&gt;</td>
  <td>Labels represent the dimensions that uniquely identify this monitored resource. At runtime expressions will be evaluated to provide values for each label. Label names are mapped to expressions as part of aspect configuration.</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.descriptor.PrincipalDescriptor"></a>
### PrincipalDescriptor
Defines a a security principal.

A principal is described by a set of attributes.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.descriptor.PrincipalDescriptor.name"></a>
 <tr>
  <td><code>name</code></td>
  <td>string</td>
  <td>Required. The name of this descriptor.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.PrincipalDescriptor.labels"></a>
 <tr>
  <td><code>labels</code></td>
  <td>repeated map&lt;string, <a href="#istio.mixer.v1.config.descriptor.ValueType">ValueType</a>&gt;</td>
  <td>Labels represent the dimensions that uniquely identify this security principal. At runtime expressions will be evaluated to provide values for each label. Label names are mapped to expressions as part of aspect configuration.</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.descriptor.QuotaDescriptor"></a>
### QuotaDescriptor
Configuration state for a particular quota.

Quotas are similar to metrics, except that they are mutated through method
calls and there are limits on the allowed values.
The descriptor below lets you define a quota and indicate the maximum
amount values of this quota are allowed to hold.

A given quota is described by a set of attributes. These attributes represent
the different dimensions to associate with the quota. A given quota holds a
unique value for potentially any combination of these attributes.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.descriptor.QuotaDescriptor.name"></a>
 <tr>
  <td><code>name</code></td>
  <td>string</td>
  <td>Required. The name of this descriptor.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.QuotaDescriptor.displayName"></a>
 <tr>
  <td><code>displayName</code></td>
  <td>string</td>
  <td>Optional. A concise name for the quota which can be displayed in user interfaces.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.QuotaDescriptor.description"></a>
 <tr>
  <td><code>description</code></td>
  <td>string</td>
  <td>Optional. A description of the quota which can be used in documentation.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.QuotaDescriptor.labels"></a>
 <tr>
  <td><code>labels</code></td>
  <td>repeated map&lt;string, <a href="#istio.mixer.v1.config.descriptor.ValueType">ValueType</a>&gt;</td>
  <td>The set of labels that are necessary to describe a specific value cell for a quota of this type.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.QuotaDescriptor.rateLimit"></a>
 <tr>
  <td><code>rateLimit</code></td>
  <td>bool</td>
  <td>Indicates whether the quota represents a rate limit or represents a resource quota.</td>
 </tr>
</table>

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

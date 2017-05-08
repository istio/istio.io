---
title: Configuration Schema
overview: Generated documentation for Mixer's configuration schema

order: 40

layout: docs
type: markdown
---

<a name="rpc_istio.mixer.v1_config"></a>
## Package istio.mixer.v1.config

<a name="rpc_istio.mixer.v1_config_index"></a>
### Index

* [Adapter](#istio.mixer.v1.config.Adapter)
(message)
* [Aspect](#istio.mixer.v1.config.Aspect)
(message)
* [AspectRule](#istio.mixer.v1.config.AspectRule)
(message)
* [AttributeManifest](#istio.mixer.v1.config.AttributeManifest)
(message)
* [DnsName](#istio.mixer.v1.config.DnsName)
(message)
* [EmailAddress](#istio.mixer.v1.config.EmailAddress)
(message)
* [GlobalConfig](#istio.mixer.v1.config.GlobalConfig)
(message)
* [IpAddress](#istio.mixer.v1.config.IpAddress)
(message)
* [ServiceConfig](#istio.mixer.v1.config.ServiceConfig)
(message)
* [Uri](#istio.mixer.v1.config.Uri)
(message)

<a name="istio.mixer.v1.config.Adapter"></a>
### Adapter
Adapter config defines specifics of adapter implementations
We define an adapter that provides "metrics" aspect
kind: istio/metrics
name: metrics-statsd
impl: “istio.io/adapters/statsd”
params:
   Host: statd.svc.cluster
   Port: 8125

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
  <td>statsd-slow</td>
 </tr>
<a name="istio.mixer.v1.config.Adapter.kind"></a>
 <tr>
  <td><code>kind</code></td>
  <td>string</td>
  <td>metrics</td>
 </tr>
<a name="istio.mixer.v1.config.Adapter.impl"></a>
 <tr>
  <td><code>impl</code></td>
  <td>string</td>
  <td>istio.statsd</td>
 </tr>
<a name="istio.mixer.v1.config.Adapter.params"></a>
 <tr>
  <td><code>params</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#struct">Struct</a></td>
  <td>Struct representation of a proto defined by the implementation based on impl {}</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.Aspect"></a>
### Aspect
Aspect is intent based. It specifies the intent "kind"
following example specifies that the user would like to collect
response_time with 3 labels (src_consumer_id, target_response_status_code,
target_service_name)

The Input section tells if target_service_name is not available it can be
computed using the given expression


     kind: istio/metrics
     params:
       metrics:
       - name: response_time     # What to call this metric outbound.
         value: metric_response_time  # from wellknown vocabulary
         metric_kind: DELTA
         labels:
         - key: src_consumer_id
         - key: target_response_status_code
         - key: target_service_name

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
  <td></td>
 </tr>
<a name="istio.mixer.v1.config.Aspect.adapter"></a>
 <tr>
  <td><code>adapter</code></td>
  <td>string</td>
  <td>optional, allows specifying an adapter</td>
 </tr>
<a name="istio.mixer.v1.config.Aspect.params"></a>
 <tr>
  <td><code>params</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#struct">Struct</a></td>
  <td>Struct representation of a proto defined by the aspect</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.AspectRule"></a>
### AspectRule
AspectRules are intent based

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
  <td>selector is an attributes based predicate. attr1 == "20" &amp;&amp; attr2 == "30"</td>
 </tr>
<a name="istio.mixer.v1.config.AspectRule.aspects"></a>
 <tr>
  <td><code>aspects[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.config.Aspect">Aspect</a></td>
  <td>The following aspects apply when the selector predicate evaluates to True</td>
 </tr>
<a name="istio.mixer.v1.config.AspectRule.rules"></a>
 <tr>
  <td><code>rules[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.config.AspectRule">AspectRule</a></td>
  <td>Nested aspect Rule is evaluated if selector predicate evaluates to True</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.AttributeManifest"></a>
### AttributeManifest
AttributeManifest describes a set of Attributes produced by some component of an Istio deployment.

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
  <td></td>
 </tr>
<a name="istio.mixer.v1.config.AttributeManifest.name"></a>
 <tr>
  <td><code>name</code></td>
  <td>string</td>
  <td>Name of the component producing these attributes. This can be the proxy (with the canonical name "istio-proxy") or the name of an attribute producing adapter in the mixer itself.</td>
 </tr>
<a name="istio.mixer.v1.config.AttributeManifest.attributes"></a>
 <tr>
  <td><code>attributes[]</code></td>
  <td>repeated <a href="#istio.mixer.v1.config.descriptor.AttributeDescriptor">AttributeDescriptor</a></td>
  <td>The set of attributes this Istio component will be responsible for producing at runtime.</td>
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
GlobalConfig defines configuration elements that are available
for the rest of the config
It is used to configure adapters and make them available in AspectRules

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
  <td></td>
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
<a name="istio.mixer.v1.config.GlobalConfig.monitored_resources"></a>
 <tr>
  <td><code>monitored_resources[]</code></td>
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
Configures a set of services
following example configures metrics collection and ratelimit for
all services


<a name="rpc_istio.mixer.v1_config_istio.mixer.v1.config.ServiceConfig_description_subsection"></a>
#### service config
subject: "namespace:ns1"
revision: "1011"
rules:
- selector: target_name == "*"
 aspects:
 - kind: metrics
   params:
     metrics:   # defines metric collection across the board.
     - name: response_time_by_status_code
       value: metric.response_time     # certain attributes are metrics
       metric_kind: DELTA
       labels:
       - key: response.status_code
 - kind: ratelimiter
   params:
     limits:  # imposes 2 limits, 100/s per source and destination
     - limit: "100/s"
       labels:
         - key: src.service_id
         - key: target.service_id
      - limit: "1000/s"  # every destination service gets 1000/s
       labels:
         - key: target.service_id

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
  <td>subject is unique for a config type 2 config with the same subject will overwrite each other</td>
 </tr>
<a name="istio.mixer.v1.config.ServiceConfig.revision"></a>
 <tr>
  <td><code>revision</code></td>
  <td>string</td>
  <td>revision of this config. This is assigned by the server</td>
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

<a name="rpc_istio.mixer.v1_config_descriptor"></a>
## Package istio.mixer.v1.config.descriptor

<a name="rpc_istio.mixer.v1_config_descriptor_index"></a>
### Index

* [AttributeDescriptor](#istio.mixer.v1.config.descriptor.AttributeDescriptor)
(message)
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

<a name="istio.mixer.v1.config.descriptor.AttributeDescriptor"></a>
### AttributeDescriptor
An `AttributeDescriptor` describes the schema of an Istio attribute type.



<a name="rpc_istio.mixer.v1_config_descriptor_istio.mixer.v1.config.descriptor.AttributeDescriptor_description_subsection_subsection"></a>
#### Istio Attributes
Istio uses `attributes` to describe runtime activities of Istio services.
An Istio attribute carries a specific piece of information about an activity,
such as the error code of an API request, the latency of an API request, the
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



<a name="rpc_istio.mixer.v1_config_descriptor_istio.mixer.v1.config.descriptor.AttributeDescriptor_description_subsection_subsection_1"></a>
#### Design
Each Istio attribute must conform to an Istio attribute type. The
`AttributeDescriptor` is used to define attribute types. Each type has a
globally unique type name, the type of the value, and a detailed description
that explains the semantics of the attribute type.

The runtime presentation of an attribute is intentionally left out of this
specification, because passing attribute using JSON, XML, or Protocol Buffers
does not change the semantics of the attribute. Different implementations
can choose different representations based on their needs.



<a name="rpc_istio.mixer.v1_config_descriptor_istio.mixer.v1.config.descriptor.AttributeDescriptor_description_subsection_subsection_2"></a>
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
<a name="istio.mixer.v1.config.descriptor.AttributeDescriptor.name"></a>
 <tr>
  <td><code>name</code></td>
  <td>string</td>
  <td><p>The name of this descriptor, referenced from individual attribute instances and other descriptors.</p><p>The format of this name is:</p>
<pre><code>Name = IDENT { &quot;.&quot; IDENT } ;
</code></pre><p>Where <code>IDENT</code> must match the regular expression <code>a-z+</code>.</p><p>Attribute descriptor names must be unique within a single Istio deployment. There is a well- known set of attributes which have succinct names. Attributes not on this list should be named with a component-specific suffix such as request.count-my.component</p></td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.AttributeDescriptor.description"></a>
 <tr>
  <td><code>description</code></td>
  <td>string</td>
  <td>An optional human-readable description of the attribute's purpose.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.AttributeDescriptor.value_type"></a>
 <tr>
  <td><code>value_type</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.ValueType">ValueType</a></td>
  <td>The type of data carried by attributes</td>
 </tr>
</table>

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
  <td>The name of this descriptor.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor.display_name"></a>
 <tr>
  <td><code>display_name</code></td>
  <td>string</td>
  <td>An optional concise name for the log entry type, which can be displayed in user interfaces. Use sentence case without an ending period, for example "Request count".</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor.description"></a>
 <tr>
  <td><code>description</code></td>
  <td>string</td>
  <td>An optional description of the log entry type, which can be used in documentation.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor.payload_format"></a>
 <tr>
  <td><code>payload_format</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.LogEntryDescriptor.PayloadFormat">PayloadFormat</a></td>
  <td>Format of the value of the payload attribute.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor.log_template"></a>
 <tr>
  <td><code>log_template</code></td>
  <td>string</td>
  <td><p>The template that will be populated with labels at runtime to generate a log message; the labels describe the parameters for this template.</p><p>The template strings must conform to go's text/template syntax.</p></td>
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
<a name="istio.mixer.v1.config.descriptor.LogEntryDescriptor.PayloadFormat.PAYLOAD_FORMAT_UNSPECIFIED"></a>
 <tr>
  <td>PAYLOAD_FORMAT_UNSPECIFIED</td>
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

A metric is dimensioned by a set of labels whose values are derived at runtime from attributes.
A given metric holds a unique value for potentially any combination of these dimensions.

The following is an example descriptor for a metric capturing the number of RPCs served, dimensioned
by the method being called and response code returned by the server:

   metric_descriptor:
     name: "response_code"
     kind: COUNTER
     value: I64
     labels:
       name: api_method
       value_type: STRING
     labels:
       name: response_code
       value_type: INT64

To actually report metrics at run time a mapping from attributes to a metric's labels must be provided.
This is provided in the aspect config; using our above descriptor we might describe the metric as:

   metric:
     descriptor: "response_code" # must match metric_descriptor.name
     value: $requestCount        # Istio expression syntax for the attribute named "request_count"
     labels:
       # either the attribute named 'apiMethod' or the literal string 'unknown'; must eval to a string
       api_method: $apiMethod | "unknown"
       # either the attribute named 'responseCode' or the literal int64 500; must eval to an int64
       response_code: $responseCode | 500

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
  <td>The name of this descriptor. This is used to refer to this descriptor in other contexts.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.display_name"></a>
 <tr>
  <td><code>display_name</code></td>
  <td>string</td>
  <td>An optional concise name for the metric, which can be displayed in user interfaces. Use sentence case without an ending period, for example "Request count".</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.description"></a>
 <tr>
  <td><code>description</code></td>
  <td>string</td>
  <td>An optional description of the metric, which should be used as the documentation for the metric.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.kind"></a>
 <tr>
  <td><code>kind</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.MetricDescriptor.MetricKind">MetricKind</a></td>
  <td>Whether the metric records instantaneous values, changes to a value, etc.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.value"></a>
 <tr>
  <td><code>value</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.ValueType">ValueType</a></td>
  <td>The type of data this metric records.</td>
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
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.linear_buckets"></a>
 <tr>
  <td><code>linear_buckets</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Linear">Linear</a> (oneof )</td>
  <td>The linear buckets.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.exponential_buckets"></a>
 <tr>
  <td><code>exponential_buckets</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Exponential">Exponential</a> (oneof )</td>
  <td>The exponential buckets.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.explicit_buckets"></a>
 <tr>
  <td><code>explicit_buckets</code></td>
  <td><a href="#istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Explicit">Explicit</a> (oneof )</td>
  <td>The explicit buckets.</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Explicit"></a>
### Explicit
Specifies a set of buckets with arbitrary widths.

There are `size(bounds) + 1` (= N) buckets. Bucket `i` has the following
boundaries:

   Upper bound (0 <= i < N-1):     bounds[i]
   Lower bound (1 <= i < N);       bounds[i - 1]

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

There are `num_finite_buckets + 2` (= N) buckets. The two additional
buckets are the underflow and overflow buckets.

Bucket `i` has the following boundaries:

   Upper bound (0 <= i < N-1):     scale * (growth_factor ^ i).
   Lower bound (1 <= i < N):       scale * (growth_factor ^ (i - 1)).

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Exponential.num_finite_buckets"></a>
 <tr>
  <td><code>num_finite_buckets</code></td>
  <td>int32</td>
  <td>Must be greater than 0.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Exponential.growth_factor"></a>
 <tr>
  <td><code>growth_factor</code></td>
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

There are `num_finite_buckets + 2` (= N) buckets. The two additional
buckets are the underflow and overflow buckets.

Bucket `i` has the following boundaries:

   Upper bound (0 <= i < N-1):     offset + (width * i).
   Lower bound (1 <= i < N):       offset + (width * (i - 1)).

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.BucketsDefinition.Linear.num_finite_buckets"></a>
 <tr>
  <td><code>num_finite_buckets</code></td>
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
<a name="istio.mixer.v1.config.descriptor.MetricDescriptor.MetricKind.METRIC_KIND_UNSPECIFIED"></a>
 <tr>
  <td>METRIC_KIND_UNSPECIFIED</td>
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
  <td>The name of this descriptor</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.MonitoredResourceDescriptor.description"></a>
 <tr>
  <td><code>description</code></td>
  <td>string</td>
  <td>An optional detailed description of the monitored resource descriptor that might be used in documentation.</td>
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
  <td>The name of this descriptor.</td>
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
  <td>The name of this descriptor.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.QuotaDescriptor.display_name"></a>
 <tr>
  <td><code>display_name</code></td>
  <td>string</td>
  <td>An optional concise name for the quota which can be displayed in user interfaces.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.QuotaDescriptor.description"></a>
 <tr>
  <td><code>description</code></td>
  <td>string</td>
  <td>An optional description of the quota which can be used in documentation.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.QuotaDescriptor.labels"></a>
 <tr>
  <td><code>labels</code></td>
  <td>repeated map&lt;string, <a href="#istio.mixer.v1.config.descriptor.ValueType">ValueType</a>&gt;</td>
  <td>The set of labels that are necessary to describe a specific value cell for a quota of this type.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.QuotaDescriptor.rate_limit"></a>
 <tr>
  <td><code>rate_limit</code></td>
  <td>bool</td>
  <td>Indicates whether the quota represents a rate limit or represents a resource quota.</td>
 </tr>
</table>

<a name="istio.mixer.v1.config.descriptor.ValueType"></a>
### ValueType
ValueType describes the types that values in the Istio system can take. These are used to describe the type of
Attributes at run time, describe the type of the result of evaluating an expression, and to describe the runtime
type of fields of other descriptors.


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.VALUE_TYPE_UNSPECIFIED"></a>
 <tr>
  <td>VALUE_TYPE_UNSPECIFIED</td>
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
<a name="istio.mixer.v1.config.descriptor.ValueType.IP_ADDRESS"></a>
 <tr>
  <td>IP_ADDRESS</td>
  <td>An IP address.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.EMAIL_ADDRESS"></a>
 <tr>
  <td>EMAIL_ADDRESS</td>
  <td>An email address.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.URI"></a>
 <tr>
  <td>URI</td>
  <td>A URI.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.DNS_NAME"></a>
 <tr>
  <td>DNS_NAME</td>
  <td>A DNS name.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.DURATION"></a>
 <tr>
  <td>DURATION</td>
  <td>A span between two points in time.</td>
 </tr>
<a name="istio.mixer.v1.config.descriptor.ValueType.STRING_MAP"></a>
 <tr>
  <td>STRING_MAP</td>
  <td>A map string -&gt; string, typically used by headers.</td>
 </tr>
</table>

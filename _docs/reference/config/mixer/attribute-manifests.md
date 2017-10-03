---
title: Attribute Manifests
overview: Describes the resource containing the collection of attributes known to Mixer at runtime.

order: 15

layout: docs
type: markdown
---
{% include home.html %}

### Index

* [AttributeManifest](#istio.mixer.v1.config.AttributeManifest)
(message)
* [AttributeInfo](#istio.mixer.v1.config.AttributeManifest.AttributeInfo)
(message)

<a name="istio.mixer.v1.config.AttributeManifest"></a> 
### AttributeManifest

AttributeManifest describes a set of Attributes produced by some component of an
Istio deployment. They encode information about attribute names and types. They
are used by Mixer to validate configuration supplied by the operator at runtime.

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
</code></pre><p>Where <code>IDENT</code> must match the regular expression <code>[a-z][a-z0-9]+</code> and <code>SEPARATOR</code> must match the regular expression <code>[\.-]</code>.</p><p>Attribute names must be unique within a single Istio deployment. The set of canonical attributes are described at <a href="https://istio.io/docs/reference/config/mixer/attribute-vocabulary.html">https://istio.io/docs/reference/config/mixer/attribute-vocabulary.html</a>. Attributes not in that list should be named with a component-specific suffix such as request.count-my.component</p></td>
 </tr>
</table>

<a name="istio.mixer.v1.config.AttributeManifest.AttributeInfo"></a>
### AttributeInfo
AttributeInfo describes the schema of an Istio `Attribute`.

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
  <td><a href="{{home}}/docs/reference/config/mixer/value-type.html#istio.mixer.v1.config.descriptor.ValueType">ValueType</a></td>
  <td>Required. The type of data carried by this attribute.</td>
 </tr>
</table>

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

### Custom Resource Definition

```yaml
kind: CustomResourceDefinition
apiVersion: apiextensions.k8s.io/v1beta1
metadata:
  name: attributemanifests.config.istio.io
  labels:
    package: istio.io.mixer
    istio: core
spec:
  group: config.istio.io
  names:
    kind: attributemanifest
    plural: attributemanifests
    singular: attributemanifest
  scope: Namespaced
  version: v1alpha2
```

### Example Manifest

```yaml
apiVersion: "config.istio.io/v1alpha2"
kind: attributemanifest
metadata:
  name: kubernetes
  namespace: istio-system
spec:
  attributes:
    source.ip:
      valueType: IP_ADDRESS
    source.labels:
      valueType: STRING_MAP
    source.name:
      valueType: STRING
    source.namespace:
      valueType: STRING
    source.service:
      valueType: STRING
    source.serviceAccount:
      valueType: STRING
    destination.ip:
      valueType: IP_ADDRESS
    destination.labels:
      valueType: STRING_MAP
    destination.name:
      valueType: STRING
    destination.namespace:
      valueType: STRING
    destination.service:
      valueType: STRING
    destination.serviceAccount:
      valueType: STRING
```
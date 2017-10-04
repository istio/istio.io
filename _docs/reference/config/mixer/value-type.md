---
title: Value Type
overview: Generated documentation for Mixer Config's Value Type

order: 50

layout: docs
type: markdown
---

### Index

* [ValueType](#istio.mixer.v1.config.descriptor.ValueType)
(enum)

<a name="istio.mixer.v1.config.descriptor.ValueType"></a>
### ValueType
ValueType describes the types that values in the Istio system can take. These
are used to describe the type of Attributes at run time, describe the type of
the result of evaluating an expression, and to describe the runtime type of
fields of templates.

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
  <td>An IP address. Encoded as bytes.</td>
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

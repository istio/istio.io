---
title: quota Config
overview: Generated documentation for Mixer's Template Configuration Schema

order: 1190

layout: docs
type: markdown
---
{% include home.html %}

<a name="rpcQuota"></a>
## Package quota

<a name="rpcQuotaIndex"></a>
### Index

* [Template](#quota.Template)
(message)

<a name="quota.Template"></a>
### Template
Quota represents a piece of data to check Quota for.

When writing the configuration, the value for the fields associated with this template can either be a
literal or an [expression]({{home}}/docs/reference/config/mixer/expression-language.html). Please note that if the datatype of a field is not istio.mixer.v1.config.descriptor.ValueType,
then the expression's [inferred type]({{home}}/docs/reference/config/mixer/expression-language.html#type-checking) must match the datatype of the field.

Example config:

```
apiVersion: "config.istio.io/v1alpha2"
kind: quota
metadata:
  name: requestcount
  namespace: istio-config-default
spec:
  dimensions:
    source: source.labels["app"] | source.service | "unknown"
    sourceVersion: source.labels["version"] | "unknown"
    destination: destination.labels["app"] | destination.service | "unknown"
    destinationVersion: destination.labels["version"] | "unknown"
```

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="quota.Template.dimensions"></a>
 <tr>
  <td><code>dimensions</code></td>
  <td>repeated map&lt;string, <a href="{{home}}/docs/reference/config/mixer/istio.mixer.v1.config.descriptor#ValueType">ValueType</a>&gt;</td>
  <td>The unique identity of the particular quota to manipulate.</td>
 </tr>
</table>

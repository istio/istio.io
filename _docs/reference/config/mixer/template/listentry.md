---
title: listentry Config
overview: Generated documentation for Mixer's Template Configuration Schema

order: 1160

layout: docs
type: markdown
---


<a name="rpcListentryIndex"></a>
### Index

* [Template](#listentry.Template)
(message)

<a name="listentry.Template"></a>
### Template
ListEntry is used to verify the presence/absence of a string
within a list.

When writing the configuration, the value for the fields associated with this template can either be a
literal or an [expression](https://istio.io/docs/reference/config/mixer/expression-language.html). Please note that if the datatype of a field is not istio.mixer.v1.config.descriptor.ValueType,
then the expression's [inferred type](https://istio.io/docs/reference/config/mixer/expression-language.html#type-checking) must match the datatype of the field.

Example config:

```
apiVersion: "config.istio.io/v1alpha2"
kind: listentry
metadata:
  name: appversion
  namespace: istio-config-default
spec:
  value: source.labels["version"]
```

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="listentry.Template.value"></a>
 <tr>
  <td><code>value</code></td>
  <td>string</td>
  <td>Specifies the entry to verify in the list.</td>
 </tr>
</table>

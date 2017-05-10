---
title: quotas
overview: Generated documentation for Mixer's Aspect Configuration Schema

order: 1180

layout: docs
type: markdown
---


<a name="rpcAspect.Index"></a>
### Index

* [QuotasParams](#aspect.QuotasParams)
(message)
* [QuotasParams.Quota](#aspect.QuotasParams.Quota)
(message)

<a name="aspect.QuotasParams"></a>
### QuotasParams
Configures a quotas aspect.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="aspect.QuotasParams.quotas"></a>
 <tr>
  <td><code>quotas[]</code></td>
  <td>repeated <a href="#aspect.QuotasParams.Quota">Quota</a></td>
  <td>The set of quotas that will be populated and handed to aspects at run time.</td>
 </tr>
</table>

<a name="aspect.QuotasParams.Quota"></a>
### Quota

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="aspect.QuotasParams.Quota.descriptorName"></a>
 <tr>
  <td><code>descriptorName</code></td>
  <td>string</td>
  <td>Must match the name of some quotaDescriptor in the global config.</td>
 </tr>
<a name="aspect.QuotasParams.Quota.labels"></a>
 <tr>
  <td><code>labels</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td>Map of quotaDescriptor label name to attribute expression. At run time each expression will be evaluated to determine the value provided to the aspect. The result of evaluating the expression must match the ValueType of the label in the quotaDescriptor.</td>
 </tr>
<a name="aspect.QuotasParams.Quota.maxAmount"></a>
 <tr>
  <td><code>maxAmount</code></td>
  <td>int64</td>
  <td>The upper limit for this quota.</td>
 </tr>
<a name="aspect.QuotasParams.Quota.expiration"></a>
 <tr>
  <td><code>expiration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>The amount of time allocated quota remains valid before it is automatically released. This is only meaningful for quotas annotated as rate limits, otherwise the value must be zero.</td>
 </tr>
</table>

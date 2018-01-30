---
title: memquota Config
overview: Generated documentation for Mixer's memquota Adapter Configuration Schema

order: 30

layout: docs
type: markdown
---


<a name="rpcAdapter.memquota.configIndex"></a>
### Index

* [Params](#adapter.memquota.config.Params)
(message)
* [Params.Override](#adapter.memquota.config.Params.Override)
(message)
* [Params.Quota](#adapter.memquota.config.Params.Quota)
(message)

<a name="adapter.memquota.config.Params"></a>
### Params

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.memquota.config.Params.quotas"></a>
 <tr>
  <td><code>quotas[]</code></td>
  <td>repeated <a href="#adapter.memquota.config.Params.Quota">Quota</a></td>
  <td>The set of known quotas.</td>
 </tr>
<a name="adapter.memquota.config.Params.minDeduplicationDuration"></a>
 <tr>
  <td><code>minDeduplicationDuration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Minimum number of seconds that deduplication is possible for a given operation.</td>
 </tr>
</table>

<a name="adapter.memquota.config.Params.Override"></a>
### Override

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.memquota.config.Params.Override.dimensions"></a>
 <tr>
  <td><code>dimensions</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td>The specific dimensions for which this override applies. String representation of instance dimensions is used to check against configured dimensions.</td>
 </tr>
<a name="adapter.memquota.config.Params.Override.maxAmount"></a>
 <tr>
  <td><code>maxAmount</code></td>
  <td>int64</td>
  <td>The upper limit for this quota.</td>
 </tr>
<a name="adapter.memquota.config.Params.Override.validDuration"></a>
 <tr>
  <td><code>validDuration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>The amount of time allocated quota remains valid before it is automatically released. This is only meaningful for rate limit quotas, otherwise the value must be zero.</td>
 </tr>
</table>

<a name="adapter.memquota.config.Params.Quota"></a>
### Quota

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.memquota.config.Params.Quota.name"></a>
 <tr>
  <td><code>name</code></td>
  <td>string</td>
  <td>The name of the quota</td>
 </tr>
<a name="adapter.memquota.config.Params.Quota.maxAmount"></a>
 <tr>
  <td><code>maxAmount</code></td>
  <td>int64</td>
  <td>The upper limit for this quota.</td>
 </tr>
<a name="adapter.memquota.config.Params.Quota.validDuration"></a>
 <tr>
  <td><code>validDuration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>The amount of time allocated quota remains valid before it is automatically released. This is only meaningful for rate limit quotas, otherwise the value must be zero.</td>
 </tr>
<a name="adapter.memquota.config.Params.Quota.overrides"></a>
 <tr>
  <td><code>overrides[]</code></td>
  <td>repeated <a href="#adapter.memquota.config.Params.Override">Override</a></td>
  <td>Overrides associated with this quota. The first matching override is applied.</td>
 </tr>
</table>

---
title: ipListChecker
overview: ipListChecker adapter configuration schema

order: 20

layout: docs
type: markdown
---


<a name="adapter.ipListChecker.Params"></a>
### Params

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.ipListChecker.Params.providerUrl"></a>
 <tr>
  <td><code>providerUrl</code></td>
  <td>string</td>
  <td>Where to find the list to check against</td>
 </tr>
<a name="adapter.ipListChecker.Params.refreshInterval"></a>
 <tr>
  <td><code>refreshInterval</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Determines how often the provider is polled for an updated list</td>
 </tr>
<a name="adapter.ipListChecker.Params.ttl"></a>
 <tr>
  <td><code>ttl</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Indicates how long to keep a list before discarding it. Typically, the TTL value should be set to noticeably longer (&gt; 2x) than the refresh interval to ensure continued operation in the face of transient server outages.</td>
 </tr>
</table>

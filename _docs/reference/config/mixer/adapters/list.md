---
title: listchecker
overview: listchecker adapter configuration schema

order: 20

layout: docs
type: markdown
---


<a name="adapter.listchecker.Params"></a>
### Params

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.listchecker.Params.providerUrl"></a>
 <tr>
  <td><code>providerUrl</code></td>
  <td>string</td>
  <td>Where to find the list to check against</td>
 </tr>
<a name="adapter.listchecker.Params.overrides"></a>
 <tr>
  <td><code>overrides</code></td>
  <td>repeated string</td>
  <td>List entries that are consulted first, before the list from the server</td>
 </tr>
<a name="adapter.listchecker.Params.blacklist"></a>
 <tr>
  <td><code>blacklist</code></td>
  <td>bool</td>
  <td>Whether the list operates as a blacklist or a whitelist.</td>
 </tr>
<a name="adapter.listchecker.Params.refreshInterval"></a>
 <tr>
  <td><code>refreshInterval</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Determines how often the provider is polled for an updated list</td>
 </tr>
<a name="adapter.listchecker.Params.ttl"></a>
 <tr>
  <td><code>ttl</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Indicates how long to keep a list before discarding it. Typically, the TTL value should be set to noticeably longer (&gt; 2x) than the refresh interval to ensure continued operation in the face of transient server outages.</td>
 </tr>
</table>

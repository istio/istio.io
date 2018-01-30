---
title: list Config
overview: Generated documentation for Mixer's list Adapter Configuration Schema

order: 20

layout: docs
type: markdown
---


<a name="rpcAdapter.list.configIndex"></a>
### Index

* [Params](#adapter.list.config.Params)
(message)
* [Params.ListEntryType](#adapter.list.config.Params.ListEntryType)
(enum)

<a name="adapter.list.config.Params"></a>
### Params

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.list.config.Params.providerUrl"></a>
 <tr>
  <td><code>providerUrl</code></td>
  <td>string</td>
  <td>Where to find the list to check against. This may be ommited for a completely local list.</td>
 </tr>
<a name="adapter.list.config.Params.refreshInterval"></a>
 <tr>
  <td><code>refreshInterval</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Determines how often the provider is polled for an updated list</td>
 </tr>
<a name="adapter.list.config.Params.ttl"></a>
 <tr>
  <td><code>ttl</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Indicates how long to keep a list before discarding it. Typically, the TTL value should be set to noticeably longer (&gt; 2x) than the refresh interval to ensure continued operation in the face of transient server outages.</td>
 </tr>
<a name="adapter.list.config.Params.cachingInterval"></a>
 <tr>
  <td><code>cachingInterval</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Indicates the amount of time a caller of this adapter can cache an answer before it should ask the adapter again.</td>
 </tr>
<a name="adapter.list.config.Params.cachingUseCount"></a>
 <tr>
  <td><code>cachingUseCount</code></td>
  <td>int32</td>
  <td>Indicates the number of times a caller of this adapter can use a cached answer before it should ask the adapter again.</td>
 </tr>
<a name="adapter.list.config.Params.overrides"></a>
 <tr>
  <td><code>overrides[]</code></td>
  <td>repeated string</td>
  <td>List entries that are consulted first, before the list from the server</td>
 </tr>
<a name="adapter.list.config.Params.entryType"></a>
 <tr>
  <td><code>entryType</code></td>
  <td><a href="#adapter.list.config.Params.ListEntryType">ListEntryType</a></td>
  <td>Determines the kind of list entry and overrides.</td>
 </tr>
<a name="adapter.list.config.Params.blacklist"></a>
 <tr>
  <td><code>blacklist</code></td>
  <td>bool</td>
  <td>Whether the list operates as a blacklist or a whitelist.</td>
 </tr>
</table>

<a name="adapter.list.config.Params.ListEntryType"></a>
### ListEntryType


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="adapter.list.config.Params.ListEntryType.STRINGS"></a>
 <tr>
  <td>STRINGS</td>
  <td>List entries are treated as plain strings.</td>
 </tr>
<a name="adapter.list.config.Params.ListEntryType.CASE_INSENSITIVE_STRINGS"></a>
 <tr>
  <td>CASE_INSENSITIVE_STRINGS</td>
  <td>List entries are treated as case-insensitive strings.</td>
 </tr>
<a name="adapter.list.config.Params.ListEntryType.IP_ADDRESSES"></a>
 <tr>
  <td>IP_ADDRESSES</td>
  <td>List entries are treated as IP addresses and ranges.</td>
 </tr>
</table>

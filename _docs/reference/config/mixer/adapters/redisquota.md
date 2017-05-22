---
title: redisquota
overview: redisquota adapter configuration schema

order: 60

layout: docs
type: markdown
---


<a name="adapter.redisquota.Params"></a>
### Params

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.redisquota.Params.minDeduplicationDuration"></a>
 <tr>
  <td><code>minDeduplicationDuration</code></td>
  <td><a href="https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration">Duration</a></td>
  <td>Minimum number of seconds that deduplication is possible for a given operation.</td>
 </tr>
<a name="adapter.redisquota.Params.redisServerUrl"></a>
 <tr>
  <td><code>redisServerUrl</code></td>
  <td>string</td>
  <td>Redis network address</td>
 </tr>
<a name="adapter.redisquota.Params.socketType"></a>
 <tr>
  <td><code>socketType</code></td>
  <td>string</td>
  <td>Network for communicating with redis, i.e., "tcp"</td>
 </tr>
<a name="adapter.redisquota.Params.connectionPoolSize"></a>
 <tr>
  <td><code>connectionPoolSize</code></td>
  <td>int64</td>
  <td>Maximum number of idle connections to redis</td>
 </tr>
<a name="adapter.redisquota.Params.rateLimitAlgorithm"></a>
 <tr>
  <td><code>rateLimitAlgorithm</code></td>
  <td>string</td>
  <td>Algorithm for rate-limiting: either fixed-window or rolling-window. The fixed-window approach can allow 2x peak specified rate, whereas the rolling-window doesn't. The rolling-window algorithm's additional precision comes at the cost of increased redis resource usage.</td>
 </tr>
</table>

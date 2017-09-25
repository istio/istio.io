---
title: stdio Config
overview: Generated documentation for Mixer's stdio Adapter Configuration Schema

order: 70

layout: docs
type: markdown
---


<a name="rpcAdapter.stdio.configIndex"></a>
### Index

* [Params](#adapter.stdio.config.Params)
(message)
* [Params.Level](#adapter.stdio.config.Params.Level)
(enum)
* [Params.Stream](#adapter.stdio.config.Params.Stream)
(enum)

<a name="adapter.stdio.config.Params"></a>
### Params

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="adapter.stdio.config.Params.logStream"></a>
 <tr>
  <td><code>logStream</code></td>
  <td><a href="#adapter.stdio.config.Params.Stream">Stream</a></td>
  <td>Selects which standard stream to write to for log entries. STDERR is the default Stream.</td>
 </tr>
<a name="adapter.stdio.config.Params.severityLevels"></a>
 <tr>
  <td><code>severityLevels</code></td>
  <td>repeated map&lt;string, <a href="#adapter.stdio.config.Params.Level">Level</a>&gt;</td>
  <td>Maps from severity strings as specified in LogEntry instances to the set of levels supported by this adapter.</td>
 </tr>
<a name="adapter.stdio.config.Params.metricLevel"></a>
 <tr>
  <td><code>metricLevel</code></td>
  <td><a href="#adapter.stdio.config.Params.Level">Level</a></td>
  <td>The level to assign to metrics being output.</td>
 </tr>
<a name="adapter.stdio.config.Params.outputAsJson"></a>
 <tr>
  <td><code>outputAsJson</code></td>
  <td>bool</td>
  <td>Whether to output a console-friendly or json-friendly format</td>
 </tr>
</table>

<a name="adapter.stdio.config.Params.Level"></a>
### Level
Importance level for individual items output by this adapter.


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="adapter.stdio.config.Params.Level.INFO"></a>
 <tr>
  <td>INFO</td>
  <td></td>
 </tr>
<a name="adapter.stdio.config.Params.Level.WARNING"></a>
 <tr>
  <td>WARNING</td>
  <td></td>
 </tr>
<a name="adapter.stdio.config.Params.Level.ERROR"></a>
 <tr>
  <td>ERROR</td>
  <td></td>
 </tr>
</table>

<a name="adapter.stdio.config.Params.Stream"></a>
### Stream
Stream is used to select between different log output sinks.


<table>
 <tr>
  <th>Value</th>
  <th>Description</th>
 </tr>
<a name="adapter.stdio.config.Params.Stream.STDOUT"></a>
 <tr>
  <td>STDOUT</td>
  <td></td>
 </tr>
<a name="adapter.stdio.config.Params.Stream.STDERR"></a>
 <tr>
  <td>STDERR</td>
  <td></td>
 </tr>
</table>

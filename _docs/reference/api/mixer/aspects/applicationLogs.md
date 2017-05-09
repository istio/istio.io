---
title: applicationLogs Config
overview: Generated documentation for Mixer's Aspect Configuration Schema

order: 1130

layout: docs
type: markdown
---


<a name="rpcAspect.configIndex"></a>
### Index

* [ApplicationLogsParams](#aspect.config.ApplicationLogsParams)
(message)
* [ApplicationLogsParams.ApplicationLog](#aspect.config.ApplicationLogsParams.ApplicationLog)
(message)

<a name="aspect.config.ApplicationLogsParams"></a>
### ApplicationLogsParams
Configures an individual application-logs aspect.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="aspect.config.ApplicationLogsParams.logName"></a>
 <tr>
  <td><code>logName</code></td>
  <td>string</td>
  <td>Identifies a collection of related log entries.</td>
 </tr>
<a name="aspect.config.ApplicationLogsParams.logs"></a>
 <tr>
  <td><code>logs[]</code></td>
  <td>repeated <a href="#aspect.config.ApplicationLogsParams.ApplicationLog">ApplicationLog</a></td>
  <td></td>
 </tr>
</table>

<a name="aspect.config.ApplicationLogsParams.ApplicationLog"></a>
### ApplicationLog

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="aspect.config.ApplicationLogsParams.ApplicationLog.descriptorName"></a>
 <tr>
  <td><code>descriptorName</code></td>
  <td>string</td>
  <td>Must match the name of some LogEntryDescriptor.</td>
 </tr>
<a name="aspect.config.ApplicationLogsParams.ApplicationLog.severity"></a>
 <tr>
  <td><code>severity</code></td>
  <td>string</td>
  <td>The expression to evaluate to determine this log's severity at runtime.</td>
 </tr>
<a name="aspect.config.ApplicationLogsParams.ApplicationLog.timestamp"></a>
 <tr>
  <td><code>timestamp</code></td>
  <td>string</td>
  <td>The expression to evaluate to determine this log's timestamp.</td>
 </tr>
<a name="aspect.config.ApplicationLogsParams.ApplicationLog.timeFormat"></a>
 <tr>
  <td><code>timeFormat</code></td>
  <td>string</td>
  <td>The golang time layout format string used to print the timestamp</td>
 </tr>
<a name="aspect.config.ApplicationLogsParams.ApplicationLog.templateExpressions"></a>
 <tr>
  <td><code>templateExpressions</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td>Map of template variable name to expression for the descriptor's logTemplate. At run time each expression will be evaluated, and together they will provide values for the log's template string. Labels and template expressions do not mix: if the result of some expression is needed for both constructing the payload and for dimensioning the log entry, it must be included both in these expressions and in the <code>labels</code> expressions.</td>
 </tr>
<a name="aspect.config.ApplicationLogsParams.ApplicationLog.labels"></a>
 <tr>
  <td><code>labels</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td>Map of LogEntryDescriptor label name to attribute expression. At run time each expression will be evaluated to determine the value that will be used to fill in the log template. The result of evaluating the expression must match the ValueType of the label in the LogEntryDescriptor.</td>
 </tr>
</table>

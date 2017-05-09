---
title: accessLogs Config
overview: Generated documentation for Mixer's Aspect Configuration Schema

order: 1120

layout: docs
type: markdown
---


<a name="rpcAspect.configIndex"></a>
### Index

* [AccessLogsParams](#aspect.config.AccessLogsParams)
(message)
* [AccessLogsParams.AccessLog](#aspect.config.AccessLogsParams.AccessLog)
(message)

<a name="aspect.config.AccessLogsParams"></a>
### AccessLogsParams
Example usage:
    kind: access-logs
    params:
      logName: "accessLog"
      log:
        logFormat: COMMON
        templateExpressions:
           originIp: origin.ip
           sourceUser: origin.user
           timestamp: request.time
           method: request.method | ""
           url: request.path
           protocol: request.scheme
           responseCode: response.code
           responseSize: response.size
        labels:
           originIp: origin.ip
           sourceUser: origin.user
           timestamp: request.time
           method: request.method | ""
           url: request.path
           protocol: request.scheme
           responseCode: response.code
           responseSize: response.size

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="aspect.config.AccessLogsParams.logName"></a>
 <tr>
  <td><code>logName</code></td>
  <td>string</td>
  <td>Identifies a collection of related log entries.</td>
 </tr>
<a name="aspect.config.AccessLogsParams.log"></a>
 <tr>
  <td><code>log</code></td>
  <td><a href="#aspect.config.AccessLogsParams.AccessLog">AccessLog</a></td>
  <td>The log that will be constructed and handed to the aspect at runtime.</td>
 </tr>
</table>

<a name="aspect.config.AccessLogsParams.AccessLog"></a>
### AccessLog
Describes how attributes must be evaluated to produce values for a log message.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="aspect.config.AccessLogsParams.AccessLog.descriptorName"></a>
 <tr>
  <td><code>descriptorName</code></td>
  <td>string</td>
  <td>Only used if logFormat is CUSTOM. Links this AccessLog to a LogEntryDescriptor that describes the log's template.</td>
 </tr>
<a name="aspect.config.AccessLogsParams.AccessLog.templateExpressions"></a>
 <tr>
  <td><code>templateExpressions</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td>Map of template variable name to expression for the descriptor's logTemplate. At run time each expression will be evaluated, and together they will provide values for the log's template string. Labels and template expressions do not mix: if the result of some expression is needed for both constructing the payload and for dimensioning the log entry, it must be included both in these expressions and in the <code>labels</code> expressions.</td>
 </tr>
<a name="aspect.config.AccessLogsParams.AccessLog.labels"></a>
 <tr>
  <td><code>labels</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td>Map of LogEntryDescriptor label name to attribute expression. At run time each expression will be evaluated to determine the value that will be used to fill in the log template. The result of evaluating the expression must match the ValueType of the label in the LogEntryDescriptor.</td>
 </tr>
</table>

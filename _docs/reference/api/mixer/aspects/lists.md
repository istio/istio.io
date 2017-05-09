---
title: lists Config
overview: Generated documentation for Mixer's Aspect Configuration Schema

order: 1160

layout: docs
type: markdown
---


<a name="rpcAspect.configIndex"></a>
### Index

* [ListsParams](#aspect.config.ListsParams)
(message)

<a name="aspect.config.ListsParams"></a>
### ListsParams
Configures a lists aspect.

Example:
   kind: lists
   params:
	    blacklist: true
     checkExpression: source.ip

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="aspect.config.ListsParams.blacklist"></a>
 <tr>
  <td><code>blacklist</code></td>
  <td>bool</td>
  <td>blacklist determines if this behaves like a blacklist default is whitelist</td>
 </tr>
<a name="aspect.config.ListsParams.checkExpression"></a>
 <tr>
  <td><code>checkExpression</code></td>
  <td>string</td>
  <td>checkExpression is the expression evaluated at runtime to derive the value that is checked against the list</td>
 </tr>
</table>

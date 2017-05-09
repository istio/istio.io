---
title: attrgen Config
overview: Generated documentation for Mixer's Aspect Configuration Schema

order: 1140

layout: docs
type: markdown
---


<a name="rpcAspect.configIndex"></a>
### Index

* [AttributesGeneratorParams](#aspect.config.AttributesGeneratorParams)
(message)

<a name="aspect.config.AttributesGeneratorParams"></a>
### AttributesGeneratorParams
Configures an AttributesGenerator aspect.

The following config specifies two adapters (mixerInfo and k8sPodInfo)
that will be used to generate attributes for use within in Mixer:

aspects:
- kind: attributes
  adapter: mixerInfo
  params:
    attributeBindings:
      mixerVersion: version
      mixerBuildId: buildID
      mixerBuildStatus: buildStatus
- kind: attributes
  adapter: k8sPodInfo
  params:
    inputExpressions:
      srcIP: source.ip | "unknown"
      tgtIP: target.ip | "unknown"
    attributeBindings:
      sourceName: srcName
      targetName: tgtName

The mixerInfo adapter takes no input arguments and produces three output
values (version, buildID, and buildStatus). Those three output values are
mapped into three attributes (mixerVersion, mixerBuildId, and
mixerBuildStatus) via the attributeBindings.

Similarly, the k8sPodInfo adapter takes two inputs (srcIp and tgtIp). Their
values are generated from the expressions that reference mixer attributes.
The adapter produces two outputs (srcName and tgtName) that are mapped into
mixer attributes (sourceName and targetName) by the attributeBindings.

<table>
 <tr>
  <th>Field</th>
  <th>Type</th>
  <th>Description</th>
 </tr>
<a name="aspect.config.AttributesGeneratorParams.inputExpressions"></a>
 <tr>
  <td><code>inputExpressions</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td>Map of input params name to attribute expressions. At runtime, each expression will be evaluated to determine the input value provided to the aspect.</td>
 </tr>
<a name="aspect.config.AttributesGeneratorParams.attributeBindings"></a>
 <tr>
  <td><code>attributeBindings</code></td>
  <td>repeated map&lt;string, string&gt;</td>
  <td>Map of attribute descriptor names to the names of values produced by an adapter. This map will be used to translate from adapter outputs into mixer attributes.</td>
 </tr>
</table>

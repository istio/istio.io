---
title: reportnothing Config
overview: Generated documentation for Mixer's Template Configuration Schema

order: 1200

layout: docs
type: markdown
---


<a name="rpcReportnothingIndex"></a>
### Index

* [Template](#reportnothing.Template)
(message)

<a name="reportnothing.Template"></a>
### Template
ReportNothing represents an empty block of data that is used for Report-capable
adapters which don't require any parameters. This is primarily intended for testing
scenarios.

Example config:

```
apiVersion: "config.istio.io/v1alpha2"
kind: reportnothing
metadata:
  name: reportrequest
  namespace: istio-config-default
spec:
```

NOTE: _No fields in this message type.__

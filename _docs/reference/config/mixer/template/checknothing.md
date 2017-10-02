---
title: checknothing Config
overview: Generated documentation for Mixer's Template Configuration Schema

order: 1150

layout: docs
type: markdown
---


<a name="rpcChecknothingIndex"></a>
### Index

* [Template](#checknothing.Template)
(message)

<a name="checknothing.Template"></a>
### Template
CheckNothing represents an empty block of data that is used for Check-capable
adapters which don't require any parameters. This is primarily intended for testing
scenarios.

Example config:

```
apiVersion: "config.istio.io/v1alpha2"
kind: checknothing
metadata:
  name: denyrequest
  namespace: istio-config-default
spec:
```

NOTE: _No fields in this message type.__

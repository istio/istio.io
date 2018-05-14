---
title: Can I enable Istio Auth with some services while disable others in the same cluster?
order: 30
type: markdown
---
Starting with release 0.3, you can use service-level annotations to disable (or enable) Istio Auth for particular service-port. 
The annotation key should be `auth.istio.io/{port_number}`, and the value should be `NONE` (to disable), or `MUTUAL_TLS` (to enable).

  Example: disable Istio Auth on port 9080 for service `details`.

```yaml
kind: Service
metadata:
name: details
labels:
  app: details
annotations:
  auth.istio.io/9080: NONE
```

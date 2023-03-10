---
---
When using the `default` tag alongside an existing non-revisioned Istio installation it is recommended to remove the old
`MutatingWebhookConfiguration` (typically called `istio-sidecar-injector`) to avoid having both the older and newer control
planes attempt injection.

---
title: Kubernetes - How do I check if my cluster has enabled the alpha features required for automatic sidecar injection?
order: 10
type: markdown
---
{% include home.html %}

Automatic sidecar injection requires the
[initializer alpha feature](https://kubernetes.io/docs/admin/extensible-admission-controllers/#enable-initializers-alpha-feature).
Run the following command to check if the initializer has been enabled
(empty output indicates that initializers are not enabled):

```bash
kubectl api-versions | grep admissionregistration
```

In addition, the Kubernetes API server must be started with the Initializer plugin [enabled](https://kubernetes.io/docs/admin/extensible-admission-controllers/#enable-initializers-alpha-feature). Failure to enable the `Initializer` plugin will result in the following error when trying to create the initializer deployment.

> The Deployment "istio-initializer" is invalid: metadata.initializers.pending: Invalid value: "null": must be non-empty when result is not set

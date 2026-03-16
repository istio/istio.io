---
---
{{< warning >}}
If attempting to install and manage Istio using `helm template`, please note the following caveats:

1. The Istio namespace (`istio-system` by default) must be created manually.

1. Resources may not be installed with the same sequencing of dependencies as
`helm install`

1. This method is not tested as part of Istio releases.

1. While `helm install` will automatically detect environment specific settings from your Kubernetes context,
`helm template` cannot as it runs offline, which may lead to unexpected results. In particular, you must ensure
that you follow [these steps](/docs/ops/best-practices/security/#configure-third-party-service-account-tokens) if your
Kubernetes environment does not support third party service account tokens.

1. `kubectl apply` of the generated manifest may show transient errors due to resources not being available in the
cluster in the correct order.

1. `helm install` automatically prunes any resources that should be removed when the configuration changes (e.g.
if you remove a gateway). This does not happen when you use `helm template` with `kubectl`, and these
resources must be removed manually.

1. If you apply generated manifests using `kubectl apply --server-side` — including GitOps tools
such as Argo CD and Flux that use `helm template` with server-side apply — you must set
`base.validationFailurePolicy=Fail` when rendering the templates. This avoids a field manager conflict
on the `ValidatingWebhookConfiguration`, where both the chart and the istiod webhook controller attempt to
manage the `failurePolicy` field. This is not needed when using `helm install` or `helm upgrade` directly
(including Helm 4, which uses server-side apply by default), as the chart handles this automatically.

{{< /warning >}}

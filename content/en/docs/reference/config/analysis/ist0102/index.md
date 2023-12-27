---
title: NamespaceNotInjected
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

This message occurs when a namespace is missing the `istio-injection` and `istio.io/rev`
labels or when the `.values.sidecarInjectorWebhook.enableNamespacesByDefault` is not
enabled to indicate whether the namespace should be auto-injected with the sidecar.

For example, you receive this error:

{{< text plain >}}
Warn [IST0102] (Namespace default) The namespace is not enabled for Istio
injection. Run 'kubectl label namespace default istio-injection=enabled' to
enable it, or 'kubectl label namespace default istio-injection=disabled' to
explicitly mark it as not needing injection Error: Analyzer found issues.
{{< /text >}}

To resolve this problem, use a label to explicitly declare whether
or not you want the namespace to be auto-injected. For example:

{{< text bash >}}
$ kubectl label namespace <namespace-name> istio-injection=enabled
{{< /text >}}

It is strongly recommended to explicitly define the desired injection behavior.
Forgetting to add labels to a namespace is a common cause of errors.

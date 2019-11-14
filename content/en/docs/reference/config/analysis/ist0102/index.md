---
title: NamespaceNotInjected
layout: analysis-message
---

This message occurs when you have a namespace that is missing the
[annotation](/docs/reference/config/annotations/) to indicate whether the
namespace is auto-injected, for example `sidecar.istio.io/inject`.

For example, you receive this error:

{{< text plain >}}
Warn [IST0102] (Namespace default) The namespace is not enabled for Istio
injection. Run 'kubectl label namespace default istio-injection=enabled' to
enable it, or 'kubectl label namespace default istio-injection=disabled' to
explicitly mark it as not needing injection Error: Analyzer found issues.
{{< /text >}}

To resolve this problem, use an annotation to explicitly declare whether
or not you want the namespace to be auto-injected. For example:

{{< text bash >}}
$ kubectl label namespace <namespace-name> istio-injection=enabled
{{< /text >}}

It is strongly recommended to explicitly define the desired injection behavior.
Forgetting to annotate a namespace is a common cause of errors.

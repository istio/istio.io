---
title: NamespaceInjectionEnabledByDefault
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when Istio is installed with `sidecarInjectorWebhook.enableNamespacesByDefault`
set to `true`, and a namespace does not have an injection label.

With this setting, Istio injects sidecars into all namespaces that do not have an injection label.
This message is for information only.

## An example

You will receive a message like this:

{{< text plain >}}
Info [IST0148] (Namespace bookinfo) is enabled for Istio injection, as Istio is installed with enableNamespacesByDefault as true.
{{< /text >}}

## How to resolve

No action is necessary if you want sidecars in the namespace.

If you do not want sidecars in the namespace, add the `istio-injection=disabled` label:

{{< text bash >}}
$ kubectl label namespace bookinfo istio-injection=disabled
{{< /text >}}

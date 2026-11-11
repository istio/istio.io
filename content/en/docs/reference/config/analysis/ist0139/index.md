---
title: InvalidWebhook
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a sidecar injector webhook is not valid. There are two causes:

- Two or more Istio injector webhooks select the same namespaces and pods. Injection can then occur
  two times.
- An injector webhook refers to a control plane `Service` that does not exist.

These problems usually occur when an old Istio installation or revision was not removed correctly.

## An example

You will receive a message like this when webhooks overlap:

{{< text plain >}}
Error [IST0139] (MutatingWebhookConfiguration istio-sidecar-injector-canary) Webhook overlaps with others: [istio-sidecar-injector/namespace.sidecar-injector.istio.io]. This may cause injection to occur twice.
{{< /text >}}

Or like this when the control plane service is missing:

{{< text plain >}}
Error [IST0139] (MutatingWebhookConfiguration istio-sidecar-injector-canary) Injector refers to a control plane service that does not exist: istio-system/istiod-canary.
{{< /text >}}

## How to resolve

1. List the webhooks:

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfigurations
    {{< /text >}}

1. Remove the webhooks of revisions that you do not use. If you use revision tags, use
   [`istioctl tag`](/docs/reference/commands/istioctl/#istioctl-tag) to manage them.

1. Make sure that the control plane `Service` that each webhook refers to exists.

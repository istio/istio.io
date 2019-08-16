---
title: Configuration Validation Webhook
description: Describes Istio's use of Kubernetes webhooks for server-side configuration validation.
weight: 20
aliases:
    - /help/ops/setup/validation   
---

Galley’s configuration validation ensures user authored Istio
configuration is syntactically and semantically valid. It uses a
Kubernetes `ValidatingWebhook`. The `istio-galley`
`ValidationWebhookConfiguration` has two webhooks.

* `pilot.validation.istio.io` - Served on path `/admitpilot` and is
responsible for validating configuration consumed by Pilot
(e.g. `VirtualService`, Authentication).

* `mixer.validation.istio.io` - Served on path `/admitmixer` and is
responsible for validating configuration consumed by Mixer.

Both webhooks are implemented by the `istio-galley` service on
port 443. Each webhook has its own `clientConfig`, `namespaceSelector`,
and `rules` section. Both webhooks are scoped to all namespaces. The
`namespaceSelector` should be empty. Both rules apply to Istio Custom
Resource Definitions (CRDs).

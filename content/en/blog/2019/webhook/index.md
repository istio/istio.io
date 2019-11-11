---
title: Secure webhook management
description: A more secure way to manage Istio webhooks.
publishdate: 2019-11-08
attribution: Lei Tang (Google)
keywords: [security, kubernetes, webhook]
target_release: 1.4
---

Istio has two webhooks: Galley and the sidecar injector.
Galley validates Kubernetes resources and the sidecar injector injects sidecar
containers into Istio.

By default, Galley and the sidecar injector manage their own webhook configurations.
This can pose a security risk if they are compromised, for example, through buffer overflow attacks.
Configuring a webhook is a highly privileged operation as a webhook may monitor and mutate all
Kubernetes resources.

In the following example, the attacker compromises
Galley and modifies the webhook configuration of Galley to eavesdrop on all Kubernetes secrets
(the `clientConfig` is modified by the attacker to direct the `secrets` resources to
a service owned by the attacker).

{{< image width="70%"
    link="./example_attack.png"
    caption="An example attack"
    >}}

To protect against this kind of attack, Istio 1.4 introduces a new feature to securely manage
webhooks using `istioctl`:

1. `istioctl`, instead of Galley and the sidecar injector, manage the webhook configurations.
Galley and the sidecar injector are de-privileged so even if they are compromised, they
will not be able to alter the webhook configurations.

1. Before configuring a webhook, `istioctl` will verify the webhook server is up
and that the certificate chain used by the webhook server is valid. This reduces the errors
that can occur before a server is ready or if a server has invalid certificates.

To try this new feature, refer to the [Istio webhook management task](/docs/tasks/security/webhook).

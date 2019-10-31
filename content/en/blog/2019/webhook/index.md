---
title: Secure webhook management
description: A more secure way to manage Istio webhooks.
publishdate: 2019-10-29
attribution: Lei Tang (Google)
keywords: [security, kubernetes, webhook]
target_release: 1.4
---

Istio has two webhooks: Galley and Sidecar Injector. Both of them are crucial for Istio,
with Galley validating Kubernetes resources and Sidecar Injector injecting Istio
sidecar containers.

By default, Galley and Sidecar Injector manage their own webhook configurations, which may
have a security risk if they are compromised (e.g., by buffer overflow attacks). Configuring
a webhook is a highly privileged operation as a webhook may monitor and mutate all
Kubernetes resources. In the following example, the attacker compromises
Galley and modifies the webhook configuration of Galley to eavesdrop all Kubernetes secrets
(the `clientConfig` is modified by the attacker to direct the `secrets` resources to the
a service owned by the attacker).

{{< image width="70%"
    link="./example_attack.png"
    caption="An example attack"
    >}}

To protect against this kind of attack, Istio 1.4 introduces a new feature to securely manage
webhooks using `istioctl`:

1. `istioctl`, instead of Galley and Sidecar Injector, manage the webhook configurations.
Galley and Sidecar Injector are de-privileged such that even if they are compromised, they
will not be able to alter the webhook configurations.

1. Before configuring a webhook, `istioctl` will verify whether the webhook server is up
and whether the certificate chain used by the webhook server is valid, which reduces the errors
caused by an unready server and by invalid certificates.

To try this new feature, please follow its [user guide](/docs/setup/install/webhook).

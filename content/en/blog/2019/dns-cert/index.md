---
title: Istio DNS certificate management
description: Provision and manage DNS certificates in Istio.
publishdate: 2019-10-29
attribution: Lei Tang (Google)
keywords: [security, kubernetes, certificates, DNS]
target_release: 1.4
---

The DNS certificates used by Istio control plane components (e.g., Galley, Sidecar Injector)
are by default managed by Citadel, which is a large component, maintains its own private
signing key, and also acts as a CA.

In Istio 1.4, we introduce a new feature to securely provision and manage DNS certificates
signed by Kubernetes CA in Istio, which has the following advantages.

* This feature removes the dependency on Citadel for DNS certificates and is
more lightweight than Citadel.

* Unlike Citadel, this feature doesn't require maintaining a private signing key, which enhances security.

* This feature simplifies root certificate distribution to TLS clients
as there is no waiting for Citadel to generate and distribute its CA cert.

The following diagram shows the architecture of provisioning and managing DNS certificates in Istio.
Chiron is the component provisioning and managing DNS certificates in Istio.

{{< image width="50%"
    link="./architecture.png"
    caption="The architecture of provisioning and managing DNS certificates in Istio"
    >}}

To try this new feature, please follow its [user guide](/docs/tasks/security/dns-cert).

---
title: Istio DNS certificate management
description: Provision and manage DNS certificates in Istio.
publishdate: 2019-11-14
attribution: Lei Tang (Google)
keywords: [security, kubernetes, certificates, DNS]
target_release: 1.4
---

By default, Citadel manages the DNS certificates of the Istio control plane.
Citadel is a large component that maintains its own private signing key, and acts as a Certificate Authority (CA).

New in Istio 1.4, we introduce a feature to securely provision and manage DNS certificates
signed by the Kubernetes CA, which has the following advantages.

* Lighter weight DNS certificate management with no dependency on Citadel.

* Unlike Citadel, this feature doesn't maintain a private signing key, which enhances security.

* Simplified root certificate distribution to TLS clients.
Clients no longer need to wait for Citadel to generate and distribute its CA certificate.

The following diagram shows the architecture of provisioning and managing DNS certificates in Istio.
Chiron is the component provisioning and managing DNS certificates in Istio.

{{< image width="50%"
    link="./architecture.png"
    caption="The architecture of provisioning and managing DNS certificates in Istio"
    >}}

To try this new feature, refer to the [DNS certificate management task](/docs/tasks/security/dns-cert).

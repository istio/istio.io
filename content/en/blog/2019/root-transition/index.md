---
title: Extending Istio Self-Signed Root Certificate Lifetime
description: Learn how to extend the lifetime of Istio self-signed root certificate.
publishdate: 2019-06-07
attribution: Oliver Liu
keywords: [security, PKI, certificate, Citadel]
---

Istio self-signed certificates have historically had a 1 year default lifetime.
If you are using Istio self-signed certificates,
you need to schedule regular root transitions before they expire.
An expiration of a root certificate may lead to an unexpected cluster-wide outage.
The issue affects new clusters created with versions up to 1.0.7 and 1.1.7.

See [Extending Self-Signed Certificate Lifetime](/docs/ops/security/root-transition/) for
information on how to gauge the age of your certificates and how to perform rotation.

{{< tip >}}
We strongly recommend you rotate root keys and root certificates annually as a security best practice.
We will send out instructions for root key/cert rotation soon.
{{< /tip >}}

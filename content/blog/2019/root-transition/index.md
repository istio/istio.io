---
title: Extending the lifetime of the Istio self-signed root certificate
description: Learn how to extend the lifetime of the Istio self-signed root certificate.
publishdate: 2019-06-06
subtitle:
attribution: Oliver Liu
twitter:
keywords: [security, PKI, certificate, Citadel]

---

The Istio self-signed certificates have a default lifetime of 1 year.
If you are using the Istio self-signed certificates,
please schedule a root transition before it expires.
An expiration of root certificate may lead to an unexpected cluster-wide outage.
After the transition, the root certificate will be renewed to have a 10 year lifetime.

To evaluate the lifetime remaining for your root certificate, please refer to the first step in the
[procedure](/help/ops/security/root-transition/#root-transition-procedure).
We provide this [user guide](/help/ops/security/root-transition/) for you to do the root transition.

{{< tip >}}
We strongly recommend you rotate root keys and root certificates annually as a security best practice.
We will send out instructions for root key/cert rotation as a follow-up.
{{< /tip >}}

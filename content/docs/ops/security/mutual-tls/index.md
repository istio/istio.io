---
title: Mutual TLS
description: What to do if mutual TLS authentication isn't working.
weight: 30
---

If you suspect problems with mutual TLS, first ensure that [Citadel is healthy](/docs/ops/security/repairing-citadel/), and
second ensure that [keys and certificates are being delivered](/docs/ops/security/keys-and-certs/) to sidecars properly.

If everything appears to be working so far, the next step is to verify that the right [authentication policy](/docs/tasks/security/authn-policy/) is applied and
the right destination rules are in place.

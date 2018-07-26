---
title: Can I enable Istio mutual TLS with some services while disable others in the same cluster?
weight: 30
---

[Authentication policy](/docs/concepts/security/#authentication-policies) can be mesh-wide (which affects all services in the mesh), namespace-wide
(all services in the same namespace) or service specific. You can have policy or policies to setup mutual TLS for services in cluster in any way as you want.

---
title: Can I enable mutual TLS for some services while leaving it disabled for other services in the same cluster?
weight: 20
---

[Authentication policy](/pt-br/docs/concepts/security/#authentication-policies) can be mesh-wide (which affects all services in the mesh), namespace-wide
(all services in the same namespace) or service specific. You can have policy or policies to setup mutual TLS for services in a cluster in any way as you want.

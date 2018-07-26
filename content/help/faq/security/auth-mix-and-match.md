---
title: Can I enable Istio mutual TLS with some services while disable others in the same cluster?
weight: 30
---

[Authentication policy](/docs/concepts/security/#authentication-policies) can be mesh-wide (affect all services in the mesh), namespace-wide (all services in the same namespace) or service specific. In other words, you can add policy or policies to setup mutual TLS for any services in cluster as you want.

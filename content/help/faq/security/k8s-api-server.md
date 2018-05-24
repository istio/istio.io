---
title: Can I access the Kubernetes API Server with Auth enabled?
weight: 50
---
The Kubernetes API server does not support mutual TLS authentication, so
strictly speaking: no. However, if you use version 0.3 or later, see next
question to learn how to disable mTLS in upstream config on clients side so
they can access API server.

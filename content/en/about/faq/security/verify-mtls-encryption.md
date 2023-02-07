---
title: How can I verify that traffic is using mutual TLS encryption?
weight: 25
---

If you installed Istio with `values.global.proxy.privileged=true`, you can use `tcpdump` to determine encryption status. Also in Kubernetes 1.23 and later, as an alternative to installing Istio as privileged, you can use `kubectl debug` to run `tcpdump` in an [ephemeral container](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#ephemeral-container). See [Istio mutual TLS migration](/docs/tasks/security/authentication/mtls-migration) for instructions.

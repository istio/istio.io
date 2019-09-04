---
title: Automatic Sidecar Injection
description: Describes Istio's use of Kubernetes webhooks for automatic sidecar injection.
weight: 5
aliases:
    - /help/ops/setup/injection
---

Automatic sidecar injection adds the sidecar proxy into user-created
pods. It uses a `MutatingWebhook` to append the sidecar’s containers
and volumes to each pod’s template spec during creation
time. Injection can be scoped to particular sets of namespaces using
the webhooks `namespaceSelector` mechanism. Injection can also be
enabled and disabled per-pod with an annotation.

Whether or not a sidecar is injected depends on three pieces of configuration and two security rules:

Configuration:

- webhooks `namespaceSelector`
- default `policy`
- per-pod override annotation

Security rules:

- sidecars cannot be injected in the `kube-system` or `kube-public` namespaces
- sidecars cannot be injected into pods that use the host network

The following truth table shows the final injection status based on
the three configuration items. The security rules above cannot be overridden.

| `namespaceSelector` match | default `policy` | Pod override annotation `sidecar.istio.io/inject` | Sidecar injected? |
|---------------------------|------------------|---------------------------------------------------|-----------|
| yes                       | enabled          | true (default)                                    | yes       |
| yes                       | enabled          | false                                             | no        |
| yes                       | disabled         | true                                              | yes       |
| yes                       | disabled         | false (default)                                   | no        |
| no                        | enabled          | true (default)                                    | no        |
| no                        | enabled          | false                                             | no        |
| no                        | disabled         | true                                              | no        |
| no                        | disabled         | false (default)                                   | no        |

---
title: How to disable mutual TLS on clients to access the Kubernetes API Server (or any control services that don't have Istio sidecar)?
weight: 60
---

> This issue occurs when Istio is installed with global mutual TLS enabled. Using authentication policy, mutual TLS can be enabled selectively per service, hence can avoid this problem. Discussion below are for releases before 0.8.

Starting with release 0.3, edit the `mtlsExcludedServices` list in Istio config
map to contain the fully-qualified name of the API server (and any other
control services for that matter). The default value of `mtlsExcludedServices`
already contains `kubernetes.default.svc.cluster.local`, which is the default
service name of the Kubernetes API server.

For a quick reference, here are commands to edit Istio configmap and to restart pilot.
```command
$ kubectl edit configmap -n istio-system istio
$ kubectl delete pods -n istio-system -l istio=pilot
```

> Do not use this approach to disable mutual TLS for services that are managed
by Istio (i.e. using Istio sidecar). Instead, use service-level annotations
to overwrite the authentication policy (see above).

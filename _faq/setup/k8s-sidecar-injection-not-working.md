---
title: Kubernetes - How can I debug problems with automatic sidecar injection?
weight: 20
---
{% include home.html %}

Ensure that your cluster has met the
[prerequisites]({{home}}/docs/setup/kubernetes/sidecar-injection.html#automatic-sidecar-injection) for
the automatic sidecar injection. If your microservice is deployed in
kube-system, kube-public or istio-system namespaces, they are exempted
from automatic sidecar injection. Please use a different namespace
instead.

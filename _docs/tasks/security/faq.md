---
title: FAQ
overview: Common issues, known limitations and work arounds, and other frequently asked questions on this topic.

order: 100

layout: docs
type: markdown
---
{% include home.html %}

### Can a service with Istio Auth enabled communicate with a service without Istio?

Currently it is not well supported. But we do have plan to support this in the near future.

### Can I enable Istio Auth with some services while disable others in the same cluster?

No, you cannot for now. Currently we only support cluster-wise Auth enable/disable. It is
a high priority action item for us to support per-service auth.

### How can I use Kubernetes liveness and readiness to for service health check with Istio Auth enabled?

If Istio Auth is enabled, http and tcp health check from kubelet will not work since they do not have
Istio Auth issued certs. A workaround is to use command option for health check, e.g., one can install
curl in the service pod and curl itself within the pod. Moreover, this is a temporary workaround. The
Auth team is actively working on a real solution.

### Can I access the Kubernetes API Server with Auth enabled?

The Kubernetes API server does not support mutual TLS
authentication. Hence, when Istio mTLS authentication is enabled, it is
currently not possible to communicate from a pod with Istio sidecar to the
Kubernetes API server.

---
title: How can I use Kubernetes liveness and readiness for service health check with Istio Auth enabled?
weight: 40
---
If Istio Auth is enabled, http and tcp health check from kubelet will not
work since they do not have Istio Auth issued certs. A workaround is to
use a [liveness command](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#define-a-liveness-command)
for health check, e.g., one can install curl in the service pod and curl itself
within the pod. The Istio team is actively working on a solution.

An example of readinessProbe:

{{< text yaml >}}
livenessProbe:
exec:
  command:
  - curl
  - -f
  - http://localhost:8080/healthz # Replace port and URI by your actual health check
initialDelaySeconds: 10
periodSeconds: 5
{{< /text >}}

---
title: How can I use Kubernetes liveness and readiness for service health check when mutual TLS is enabled?
weight: 50
---
If mutual TLS is enabled, http and tcp health checks from the kubelet will not
work since the kubelet does not have Istio-issued certificates. A workaround is to
use a [liveness command](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#define-a-liveness-command)
for health checks, e.g., one can install `curl` in the service pod and `curl` itself
within the pod.

An example of a readiness probe:

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

If you do not want to modify the configuration file, you can enable the `PERMISSIVE`
mode for your services such they can accept both http and mutual TLS traffic. As
a result, the health check will not break. Refer to [Health checking of Istio
services](/docs/tasks/traffic-management/app-health-check/) for more information.

---
title: How can I use Kubernetes liveness and readiness for service health check when mutual TLS is enabled?
weight: 50
---
If mutual TLS is enabled, http and tcp health checks from the kubelet will
not work since the kubelet does not have Istio-issued certificates.

As of the Istio 1.0 release, we support the [`PERMISSIVE` mode](/docs/tasks/security/mtls-migration)
for Istio services so they can accept both http and mutual TLS traffic
when this mode is turned on. This can solve the health checking issue.
Please keep in mind that mutual TLS is not enforced since others can
communicate with the service with http traffic.

You can use a separate port for health check and enable mutual TLS only
on the regular service port. Refer to [Health checking of Istio
services](/docs/tasks/traffic-management/app-health-check/)
for more information.

Another workaround is to use a [liveness command](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#define-a-liveness-command)
for health checks, e.g., one can install `curl` in the service pod and
`curl` itself within the pod.

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

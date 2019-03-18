---
title: How can I use Kubernetes liveness and readiness for pod health checks when mutual TLS is enabled?
weight: 50
---

If mutual TLS is enabled, http and tcp health checks from the kubelet will not work since the kubelet does not have Istio-issued certificates.

As of the Istio 1.1 release, we have several options to solve this issue. 

You can use probe rewrite to rewrites the liveness/readiness probe such that the probe request will redirected to application directly. And you can also use a separate port for health checks and enable mutual TLS only on the regular service port. Please refer to [Health Checking of Istio Services](/help/ops/setup/app-health-check/#mutual-tls-is-enabled) for more information.

Moreover, we support the [`PERMISSIVE` mode](/docs/tasks/security/mtls-migration) for Istio services so they can accept both http and mutual TLS traffic when this mode is turned on. This can solve the health checking issue. Please keep in mind that mutual TLS is not enforced since others can communicate with the service with http traffic.

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

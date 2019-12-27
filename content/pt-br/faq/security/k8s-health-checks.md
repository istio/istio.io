---
title: How can I use Kubernetes liveness and readiness for pod health checks when mutual TLS is enabled?
weight: 50
---

If mutual TLS is enabled, HTTP and TCP health checks from the kubelet will not work without modification, since the kubelet does not have Istio-issued certificates.

As of Istio 1.1, we have several options to solve this issue.

1.  Using probe rewrite to redirect liveness and readiness requests to the
    workload directly. Please refer to [Probe Rewrite](/pt-br/docs/ops/configuration/mesh/app-health-check/#probe-rewrite)
    for more information.

1.  Using a separate port for health checks and enabling mutual TLS only on the regular service port. Please refer to [Health Checking of Istio Services](/pt-br/docs/ops/configuration/mesh/app-health-check/#separate-port) for more information.

1.  Using the [`PERMISSIVE` mode](/pt-br/docs/tasks/security/authentication/mtls-migration) for Istio services so they can accept both HTTP and mutual TLS traffic. Please keep in mind that mutual TLS is not enforced since others can communicate with the service with HTTP traffic.

1.  Using a [liveness command](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#define-a-liveness-command) for health checks, e.g., one can install `curl` in the service pod and
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

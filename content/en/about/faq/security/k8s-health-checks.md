---
title: How can I use Kubernetes liveness and readiness for pod health checks when mutual TLS is enabled?
weight: 50
---

If mutual TLS is enabled, HTTP and TCP health checks from the kubelet will not work without modification, since the kubelet does not have Istio-issued certificates.

There are several options:

1.  Using probe rewrite to redirect liveness and readiness requests to the
    workload directly. Please refer to [Probe Rewrite](/docs/ops/configuration/mesh/app-health-check/#probe-rewrite)
    for more information. This is enabled by default and recommended.

1.  Using a separate port for health checks and enabling mutual TLS only on the regular service port. Please refer to [Health Checking of Istio Services](/docs/ops/configuration/mesh/app-health-check/#separate-port) for more information.

1.  Using the [`PERMISSIVE` mode](/docs/tasks/security/authentication/mtls-migration) for the workload, so it can accept both plaintext and mutual TLS traffic. Please keep in mind that mutual TLS is not enforced with this option.

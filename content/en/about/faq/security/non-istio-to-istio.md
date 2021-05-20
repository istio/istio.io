---
title: If mutual TLS is globally enabled, can non-Istio services access Istio services?
weight: 30
---
When `STRICT` mutual TLS is enabled, non-Istio workloads cannot communicate to Istio services, as they will not have a valid Istio client certificate.

If you need to allow these clients, the mutual TLS mode can be configured to `PERMISSIVE`, allowing both plaintext and mutual TLS.
This can be done for individual workloads or the entire mesh.

See [Authentication Policy](/docs/tasks/security/authentication/authn-policy) for more details.

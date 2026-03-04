---
title: Debug Endpoints
description: Accessing istiod debug endpoints for monitoring and troubleshooting.
weight: 30
keywords: [integration,debug,authentication,istiod]
owner: istio/wg-user-experience-maintainers
test: no
---

Istiod exposes debug endpoints (e.g., `/debug/syncz`, `/debug/registryz`, `/debug/config_dump`) on multiple ports that provide monitoring and status information useful for integrations.

## Ports and protocols

- **Port 15010**: XDS debug endpoints via plaintext gRPC (`syncz`, `config_dump`)
- **Port 15012**: XDS debug endpoints via TLS/mTLS gRPC (`syncz`, `config_dump`) - recommended for production
- **Port 15014**: HTTP debug endpoints (plaintext)

## Authentication requirements

Debug endpoints require authentication via Kubernetes service account tokens or valid JWT credentials. The token must have audience `istio-ca` (configurable via the `TOKEN_AUDIENCES` environment variable on istiod).

**Port 15010 (plaintext gRPC):** When `ENABLE_DEBUG_ENDPOINT_AUTH=true`, debug endpoints require authentication. Since this port is plaintext (no TLS), the authentication check effectively blocks access unless disabled. Use port 15012 instead for authenticated XDS debug access.

**Port 15012 (TLS gRPC):** XDS debug endpoints are available via the secure TLS port. Authentication is performed via mTLS certificate validation automatically.

**Port 15014 (HTTP):** Authentication via bearer token in Authorization header or localhost bypass.

Authentication is controlled by `ENABLE_DEBUG_ENDPOINT_AUTH` (enabled by default). To disable authentication entirely and restore legacy plaintext behavior, set `ENABLE_DEBUG_ENDPOINT_AUTH=false` on istiod. Note that disabling authentication may expose sensitive cluster information.

## Namespace-based access control

When authentication is enabled:

- Service accounts from the **system namespace** (typically `istio-system`) have full access to all debug endpoints for all proxies across all namespaces.
- Service accounts from **non-system namespaces** are restricted to:
    - Specific endpoints only: `/debug/config_dump`, `/debug/ndsz`, `/debug/edsz`
    - Same-namespace proxies only (cannot view proxies from other namespaces)
- To grant additional namespaces the same full access as the system namespace, set the `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` environment variable on istiod to a comma-separated list of namespaces.
  {{< tip >}}
  `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` is available in Istio 1.29.1+, 1.28.5+, and 1.27.8+ (upcoming patch releases).
  {{< /tip >}}

## Access methods

**Via localhost (recommended):**

Port-forwarding to istiod bypasses authentication since requests come from localhost. This is how istioctl works and the recommended approach for most integrations:

{{< text bash >}}
$ kubectl port-forward -n istio-system deploy/istiod 15014:15014
$ curl http://localhost:15014/debug/syncz
{{< /text >}}

**Direct network access (for in-cluster tools):**

For tools running inside the cluster (e.g., Kiali, custom monitoring) that access istiod directly via Kubernetes service network, the service account token must:

- Have audience `istio-ca` (default)
- Be from an authorized namespace (either `istio-system` or listed in `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES`)
- Be included as a bearer token in the Authorization header

{{< text bash >}}
$ TOKEN=$(kubectl create token my-sa --audience istio-ca -n my-namespace)
$ curl -H "Authorization: Bearer $TOKEN" https://istiod.istio-system:15014/debug/syncz
{{< /text >}}

{{< warning >}}
Standard in-cluster service account tokens have audience `https://kubernetes.default.svc.cluster.local` and will not work for direct access without explicitly requesting the `istio-ca` audience.
{{< /warning >}}

## Example: Configuring namespace access

To allow a monitoring tool running in the `monitoring` namespace to access debug endpoints, add the namespace to istiod's configuration:

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istiod
  namespace: istio-system
spec:
  template:
    spec:
      containers:
      - name: discovery
        env:
        - name: DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES
          value: "monitoring,kiali-operator"
{{< /text >}}

After applying this change, service accounts from the `monitoring` and `kiali-operator` namespaces will have the same access level as `istio-system` service accounts.

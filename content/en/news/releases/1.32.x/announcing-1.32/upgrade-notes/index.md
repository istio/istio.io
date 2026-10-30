---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.32.0.
weight: 20
---

When you upgrade from Istio 1.31.0 to Istio 1.32.0, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.31.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.31.x.

## EnvoyFilter patches matching the gateway RBAC filter by name

When `ENABLE_GATEWAY_API_HTTPROUTE_AUTH=true`, the `ALLOW` action's HTTP filter on ingress
gateways is emitted as `istio.authorization.allow` instead of `envoy.filters.http.rbac`. A
distinct name is required so that route-scoped configuration can address the `ALLOW` filter
without also affecting the `DENY` and `AUDIT` filters, which continue to use
`envoy.filters.http.rbac`.

This affects any `EnvoyFilter` that matches the RBAC filter by name, for example:

```yaml
match:
  context: GATEWAY
  listener:
    filterChain:
      filter:
        name: envoy.filters.http.http_connection_manager
        subFilter:
          name: envoy.filters.http.rbac
```

Such a patch no longer matches the `ALLOW` filter. `MERGE`, `REPLACE` and `REMOVE` operations
silently stop applying to it, while `INSERT_BEFORE` and `INSERT_AFTER` drop the supplied filter
from the chain entirely rather than falling back to another position. Gateways whose only
authorization policies use the `ALLOW` action have no filter named
`envoy.filters.http.rbac` at all.

No warning is emitted when a patch fails to match unless `PILOT_ENVOY_FILTER_STATS=true` is
set on `istiod`, which exposes the `pilot_envoy_filter_status` metric.

If you rely on such a patch, either add a second `EnvoyFilter` matching
`istio.authorization.allow`, or leave `ENABLE_GATEWAY_API_HTTPROUTE_AUTH` disabled. Envoy
statistics are unaffected, as RBAC filter metrics are derived from the connection manager's
stat prefix rather than the filter name.

## Kubernetes API requests now have client-side timeouts

The defaults suit most clusters. Environments with a slow or heavily loaded API server
can raise them, or set either of them to `0` to restore the previous unbounded behavior,
with these environment variables on the affected component.

| Variable | Default | Applies to |
| --- | --- | --- |
| `ISTIO_KUBE_HEADER_TIMEOUT` | `90s` | How long any request may wait for its response headers. Must stay above the API server's `--request-timeout` (60s by default). |
| `ISTIO_KUBE_REQUEST_TIMEOUT` | `15m` | Total duration of a request that does not set its own deadline, including reading the response. |

Exec, attach, and port-forward sessions are not affected. A timeout increments
`kube_client_deadline_fired_total` and logs a warning naming the method and path.

## Unhealthy endpoints from pods and WorkloadEntries

With `PILOT_AUTO_SEND_UNHEALTHY_ENDPOINTS` enabled (the default), unready pods selected by
ServiceEntries and unhealthy health-checked WorkloadEntries can now appear in endpoint
discovery responses with unhealthy status.

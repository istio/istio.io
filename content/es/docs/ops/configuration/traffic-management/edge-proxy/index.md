---
title: Edge Proxy Configuration
description: Configure Envoy edge proxy best-practice defaults for ingress gateways.
weight: 65
keywords: [traffic-management,ingress,gateway,edge,security,hardening]
owner: istio/wg-networking-maintainers
test: n/a
---

When an Istio gateway is deployed as an edge proxy, directly exposed to untrusted
client traffic, Envoy [recommends specific settings](https://www.envoyproxy.io/docs/envoy/latest/configuration/best_practices/edge)
for buffer limits, timeouts, HTTP/2 tuning, header sanitization, and connection limits.

Istio's `ProxyConfig.ConnectionSettings` API lets you apply these recommendations in
one step using the `EDGE` profile, or configure individual settings for any proxy.

For the complete field reference, see [`ProxyConfig.ConnectionSettings`](/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig-ConnectionSettings).

## Applying the `EDGE` profile

Set `profile: EDGE` within `connectionSettings` to apply Envoy's recommended edge proxy
defaults to a gateway. The profile can be set globally via `MeshConfig` or per gateway
using a pod annotation.

### Global configuration

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      connectionSettings:
        profile: EDGE
{{< /text >}}

### Per-gateway annotation

{{< text syntax=yaml snip_id=none >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"connectionSettings": {"profile": "EDGE"}}'
{{< /text >}}

### `EDGE` profile defaults

The `EDGE` profile applies the following defaults. Explicitly setting any field
always takes precedence over profile defaults.

| Setting | Default value |
|---------|---------------|
| `listenerPerConnectionBufferLimitBytes` | `32768 (32 KiB)` |
| `clusterPerConnectionBufferLimitBytes` | `32768 (32 KiB)` |
| `httpIdleTimeout` | `3600s` (1 hour) |
| `httpRequestTimeout` | `300s` (5 minutes) |
| `httpStreamIdleTimeout` | `300s` (5 minutes) |
| `httpMaxConcurrentStreams` | 100 |
| `http2InitialStreamWindowSize` | `65536 (64 KiB)` |
| `http2InitialConnectionWindowSize` | 1048576 (1 MiB) |
| `httpRequestHeadersTimeout` | `60s` (1 minute) |
| `httpHeadersWithUnderscoresAction` | `REJECT_REQUEST` |
| `httpMergeSlashes` | true |
| `httpPathWithEscapedSlashesAction` | `UNESCAPE_AND_REDIRECT` |

{{< tip >}}
The `EDGE` profile defaults only apply to gateway (Router) proxies, even when the
setting is applied globally via `MeshConfig`. However, explicitly set
`connectionSettings` fields (without relying on profile defaults) apply to all
proxy types, including sidecars.
{{< /tip >}}

## Overriding profile defaults

You can set `profile: EDGE` and override specific settings. For example, to raise
the maximum concurrent streams limit:

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      connectionSettings:
        profile: EDGE
        httpMaxConcurrentStreams: 200
{{< /text >}}

Or via pod annotation:

{{< text syntax=yaml snip_id=none >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"connectionSettings": {"profile": "EDGE", "httpMaxConcurrentStreams": 200}}'
{{< /text >}}

## Configuring individual settings without a profile

You can set individual `connectionSettings` fields without using a profile. This is
useful when you want specific connection tuning without the full set of edge defaults.

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      connectionSettings:
        httpIdleTimeout: 600s
        httpMaxConcurrentStreams: 50
{{< /text >}}

When no profile is set, no additional defaults are applied. Only explicitly set
fields take effect.

## Global downstream connection limit

The `globalDownstreamConnectionLimit` field configures the maximum number of
downstream connections the proxy will accept. This uses Envoy's overload manager
in the bootstrap configuration.

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      connectionSettings:
        profile: EDGE
        globalDownstreamConnectionLimit: 10000
{{< /text >}}

This field takes precedence over the `ISTIO_META_GLOBAL_DOWNSTREAM_MAX_CONNECTIONS`
proxy metadata value, which in turn takes precedence over the deprecated
`overload.global_downstream_max_connections` runtime flag.

## Relationship with other APIs

**DestinationRule**: `ConnectionSettings` configures the downstream side of the
proxy (listeners and the HTTP Connection Manager), while DestinationRule's
`connectionPoolSettings` configures the upstream cluster side. Both apply
independently at different hops and do not override each other.

**Path normalization**: The `httpMergeSlashes` and `httpPathWithEscapedSlashesAction`
fields in `ConnectionSettings` take precedence over the equivalent `MeshConfig`
`pathNormalization` settings when set. For guidance on choosing path normalization
options, see the [security best practices](/docs/ops/best-practices/security/#understand-path-normalization-in-authorization-policy).

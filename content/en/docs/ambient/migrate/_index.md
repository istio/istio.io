---
title: Migrate from Sidecar to Ambient
description: Migrate an existing sidecar-based mesh to ambient mode.
weight: 12
owner: istio/wg-networking-maintainers
test: no
skip_list: true
next: /docs/ambient/migrate/before-you-begin
---

This guide walks you through migrating an existing Istio deployment from
{{< gloss >}}sidecar{{< /gloss >}} mode to {{< gloss "ambient" >}}ambient mode{{< /gloss >}}.
The migration is designed to be gradual and reversible: sidecar and ambient workloads can
coexist in the same mesh during the process, allowing you to migrate one namespace at
a time with no downtime.

## Migration strategy

The migration follows a step-by-step approach:

1. **Install ambient components:** Add ztunnel and update the CNI to support ambient mode,
   while leaving all existing sidecar workloads unchanged.
1. **Migrate policies:** Convert `VirtualService` resources to `HTTPRoute`, update
   `AuthorizationPolicy` resources to target waypoints where needed, and attach
   `RequestAuthentication` and `WasmPlugin` resources to waypoints. This step should be
   skipped if you only use L4 policies.
1. **Enable ambient mode per namespace:** Label namespaces to join the ambient mesh,
   activate waypoints, remove sidecar injection, and restart pods.

Each step is independently reversible. There is no requirement to migrate all
namespaces at once.

## Resource migration overview

The following table summarizes how sidecar-mode resources map to their ambient equivalents:

| Sidecar resource | Action in ambient mode |
|---|---|
| `VirtualService` | Migrate to `HTTPRoute` (`VirtualService` support is Alpha in ambient) |
| `DestinationRule` (traffic policies: connection pool, outlier detection, TLS) | No change; waypoints apply traffic policies |
| `DestinationRule` (routing subsets used with `HTTPRoute`) | Create version-specific Kubernetes Services as `backendRefs` for `HTTPRoute` |
| `AuthorizationPolicy` with L4 rules | No change; ztunnel enforces L4 policies directly |
| `AuthorizationPolicy` with L7 rules | Attach to waypoint using `targetRefs` |
| `RequestAuthentication` | Attach to waypoint using `targetRefs` |
| `EnvoyFilter` | Not supported on waypoints |
| `WasmPlugin` | Attach to waypoint using `targetRefs` |
| `Gateway` (networking.istio.io/v1) | No change required; Istio Gateway resources continue to work in ambient mode. Add `istio.io/ingress-use-waypoint` to route ingress traffic through a waypoint. |

## Do you need waypoint proxies?

{{< tip >}}
Waypoint proxies are **optional**. If you only need mTLS and L4 authorization policies,
you can migrate to ztunnel without deploying waypoints and without changing any existing policies.
{{< /tip >}}

You need waypoint proxies if your workloads use any of the following:

- L7 `AuthorizationPolicy` rules (matching on HTTP methods, paths, or headers).
- L7 traffic routing (retries, fault injection, header manipulation, traffic splitting) via `HTTPRoute`. If you currently use `VirtualService` for this, you will need to migrate to `HTTPRoute`, `VirtualService` support in ambient is Alpha.
- `RequestAuthentication` (JWT validation).
- L7 telemetry enrichment.

If you are unsure, the [migrate policies](/docs/ambient/migrate/migrate-policies/) page
helps you audit your existing resources.

## What is not supported

{{< tip >}}
The limitations listed below reflect the current stable Istio release. Ambient mode continues to evolve and some of these constraints may be lifted in later versions. Check the [release notes](/news/releases/) for updates specific to your Istio version.
{{< /tip >}}

The following are hard blockers, migration is not possible until these are resolved:

- **VM workloads** in the mesh. VM-based workloads cannot join the ambient mesh.
- **SPIRE** as the certificate provider. Ambient mode does not support SPIRE integration.
- **`PeerAuthentication` with `mode: DISABLE`**. Ambient always enforces mTLS between
  mesh workloads. Policies with `DISABLE` mode will be ignored and cannot be migrated.
- **Primary-remote multicluster configurations**. Only multiple-primary clusters are
  supported. Deployments with one or more remote clusters will not work correctly.

The following are known limitations that affect behavior during or after migration:

- **`EnvoyFilter` resources targeting waypoints are not supported**. If you rely on
  `EnvoyFilter` for advanced Envoy configuration on your sidecar proxies, those
  configurations cannot be carried over to waypoints. This API may be supported in a
  future release.
- **Traffic from sidecar mode workloads bypasses waypoint proxies**. During an incremental
  migration, if a sidecar mode workload calls an ambient mode workload that has a waypoint,
  the traffic bypasses the waypoint entirely. L7 policies on the waypoint are not enforced
  for that traffic until the source workload is also migrated to ambient mode.
- **Ingress gateways bypass waypoints by default**, but can be configured to route traffic
  through a waypoint by adding the `istio.io/ingress-use-waypoint` label to the Gateway
  resource.
- **Mixing `VirtualService` and `HTTPRoute` for the same workload is not supported** and
  leads to undefined behavior. Migrate each workload fully to one API before proceeding.

## Next steps

Start with [Before you begin](/docs/ambient/migrate/before-you-begin/) to verify
your environment and back up your configuration.

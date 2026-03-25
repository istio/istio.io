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
1. **Migrate policies:** Convert `VirtualService` and `DestinationRule` resources
   to Gateway API (`HTTPRoute`) equivalents, and update `AuthorizationPolicy` resources to
   target waypoints where needed. This step should be skipped if you only use L4 policies.
1. **Enable ambient mode per namespace:** Label namespaces to join the ambient mesh,
   activate waypoints, remove sidecar injection, and restart pods.

Each step is independently reversible. There is no requirement to migrate all
namespaces at once.

## Do you need waypoint proxies?

{{< tip >}}
Waypoint proxies are **optional**. If you only need mTLS and L4 authorization policies,
you can migrate entirely to ztunnel without deploying any waypoint proxies. This allows you to benefit from ambient mode's simplified operations and improved performance without needing to change your existing policies or traffic management configuration.
{{< /tip >}}

You need waypoint proxies if your workloads use any of the following:

- L7 `AuthorizationPolicy` rules (matching on HTTP methods, paths, or headers).
- L7 traffic routing (retries, fault injection, header manipulation, traffic splitting) via `HTTPRoute`. If you currently use `VirtualService` for this, you will need to migrate to `HTTPRoute`, `VirtualService` support in ambient is Alpha.
- `RequestAuthentication` (JWT validation).
- L7 telemetry enrichment.

If you are unsure, the [migrate policies](/docs/ambient/migrate/migrate-policies/) page
helps you audit your existing resources.

## What is not supported

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
- **Traffic from sidecar mode workloads and ingress gateways does not go through
  waypoint proxies**. During an incremental migration, if a sidecar mode workload calls
  an ambient mode workload that has a waypoint, the traffic bypasses the waypoint entirely.
  L7 policies on the waypoint are not enforced for that traffic until the source is also
  migrated to ambient mode.
- **Mixing `VirtualService` and `HTTPRoute` for the same workload is not supported** and
  leads to undefined behavior. Migrate each workload fully to one API before proceeding.

## Next steps

Start with [Before you begin](/docs/ambient/migrate/before-you-begin/) to verify
your environment and back up your configuration.

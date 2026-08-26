---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.31.0.
weight: 20
---

When you upgrade from Istio 1.30.0 to Istio 1.31.0, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.30.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.30.x.

## Default behavior for sending unhealthy endpoints

By default, Istio now sends unhealthy endpoints unless `OutlierDetection.minHealthPercent` is configured on a `Service`.
This can be disabled by setting `PILOT_AUTO_SEND_UNHEALTHY_ENDPOINTS` to `false`, or by using compatibility profiles.

## Existing auto-registered `WorkloadEntry` resources need re-registration or a manual label for HBONE

The HBONE tunnel label is applied only when a `WorkloadEntry` is auto-created, so workloads
auto-registered before upgrading continue to be reached over plaintext until either they
re-register (reconnect a fresh instance) or the label (`networking.istio.io/tunnel=http`)
is added to their existing `WorkloadEntry`.

## `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY` feature flag removed

The environment variable `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY` has been removed. The
behavior it controlled (spawning a separate tracing span for each upstream request for
gateway when using the Telemetry API) is now always enabled. Users who explicitly set
this variable to `false` to opt out of this behavior should be aware that the opt-out
is no longer available.

## WDS reconnect requests are larger in big ambient meshes

On reconnect, ztunnel reports the name and version of every workload (WDS) resource it
holds. This request can exceed istiod's default 4MiB gRPC receive limit, leaving ztunnel
in a reconnect loop with `ResourceExhausted: grpc: received message larger than max`
errors. Meshes could already hit the limit at roughly 55,000 workloads, since resource
names were reported before this change; the added versions grow the request by about a
third, lowering the trigger point to roughly 40,000 workloads (sooner with long resource
names or many services). If your mesh is near this scale, raise
`ISTIO_GPRC_MAXRECVMSGSIZE` on istiod — budget roughly 1MiB per 10,000 workloads and
services; for example, `--set pilot.env.ISTIO_GPRC_MAXRECVMSGSIZE=33554432` (32MiB)
covers meshes well past 300,000 resources — and watch istiod logs for the error above
after upgrading.

## The XDS `api` generator now requires a control-plane identity

Custom MCP consumers connecting to istiod's `api` generator from non-system namespaces are now rejected.
Standard sidecar, gateway, and ztunnel traffic is unaffected.
To restore the previous behavior, set `ENABLE_XDS_API_GENERATOR_AUTH=false`.

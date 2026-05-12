---
title: Announcing Istio 1.30.0
linktitle: 1.30.0
subtitle: Major Release
description: Istio 1.30 Release Announcement.
publishdate: 2026-05-14
release: 1.30.0
aliases:
    - /news/announcing-1.30
    - /news/announcing-1.30.0
---

We are pleased to announce the release of Istio 1.30. Thank you to all our contributors, testers, users and enthusiasts for helping us get the 1.30.0 release published!
We would like to thank the Release Managers for this release, **Petr McAllister** from Solo.io, **Jacek Ewertowski** from Red Hat, and **Jackson Greer** from Microsoft.

{{< relnote >}}

{{< tip >}}
Istio 1.30.0 is officially supported on Kubernetes versions 1.32 to 1.36.
{{< /tip >}}

## What's new?

### Agentgateway: experimental new gateway implementation

Istio 1.30 ships experimental support for [agentgateway](https://agentgateway.dev) as a Gateway API implementation. Agentgateway is a new gateway data plane built specifically for AI agents and MCP servers, and integrates with Istio via the `PILOT_ENABLE_AGENTGATEWAY` env var. This is early-access functionality, expect rough edges, feedback is welcome.

### Gateway API and TLSRoute improvements

This release adds support for [`TLSRoute`](https://gateway-api.sigs.k8s.io/api-types/tlsroute/) termination and mixed mode, support for TLS passthrough listeners on east-west gateways, and reports attached `ListenerSets` and routes in `Gateway` status. Combined, these changes make Istio's Gateway API implementation closer to feature parity with the in-tree spec and improve operability for multi-tenant gateway scenarios.

### Ambient mode enhancements

Several ambient features land in 1.30:

- **CIDR address support in `ServiceEntry`**. `ServiceEntry` resources can now use CIDR addresses for endpoints, enabling ambient routing for ranges of IPs without enumerating individual workloads.
- **Optional XFCC synthesis at waypoints**. With the annotation `ambient.istio.io/xfcc-include-client-identity: "true"` on a waypoint Gateway, the waypoint synthesizes `x-forwarded-client-cert` from the ztunnel-provided source workload SPIFFE identity, so upstream apps can see the originating client.
- **Configurable HBONE window sizing** via `PILOT_HBONE_INITIAL_STREAM_WINDOW_SIZE` and `PILOT_HBONE_INITIAL_CONNECTION_WINDOW_SIZE`, useful for tuning HBONE CONNECT clusters for high-throughput ambient workloads.
- **Tokio runtime metrics in ztunnel** for clearer per-instance resource visibility.

### Traffic management additions

- **Namespace-level traffic distribution annotation**. Services inherit traffic distribution from a namespace annotation when not explicitly set on the service, reducing per-service boilerplate.
- **`istio.io/connect-strategy` annotation on `ServiceEntry`** with `RACE_FIRST_TCP_CONNECT` mode, useful when DNS returns multiple A records and the client should pick the first endpoint that successfully completes TCP connect.
- **DNS upstream timeout** is now configurable via `DNS_FORWARD_TIMEOUT`, with the existing `5s` default preserved.
- **DNS failover priority** support for DNS clusters.
- **Multiple CUSTOM authorization providers per workload**, enabling different authentication schemes (OAuth, LDAP, API keys) on different API paths.
- **`TrafficExtension` API**, a single unified API for configuring Wasm and Lua extensions on Envoy-based sidecars, gateways and waypoints, replacing `WasmPlugin` as the primary proxy extensibility mechanism.

### Helm v4 support

Istio 1.30 adds support for Helm v4 (server-side apply). A long-standing issue with webhook `failurePolicy` field ownership during upgrades has also been addressed. Users running Helm v4 should upgrade smoothly without the previous workarounds.

### Security

- **Debug endpoint authentication tightened.** XDS debug endpoints (`syncz`, `config_dump`) on port 15010 now require authentication when `ENABLE_DEBUG_ENDPOINT_AUTH=true` (default). A new `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` setting lets operators allow specific namespaces beyond the system namespace. See the [upgrade notes](upgrade-notes/) for the breaking-change details.
- **TLS minimum version flag** for `pilot-discovery` (`--tls-min-version`), letting operators raise the floor for control-plane TLS.
- **Default registry** for Istio images is now `registry.istio.io`. The previous registry remains accessible, but new installs default to the new location.

### Installation and operability

- **Configurable port overrides** for the network gateway service via `networkGatewayPorts` Helm values, plus template validation to fail early when `service.ports` is empty and `networkGateway` is not set.
- **`WaypointBound` status condition** on `WorkloadEntry` resources, reporting whether each workload is currently bound to a waypoint.
- **`dnsPolicy` and `dnsConfig` fields** on the ztunnel Helm chart for environments with non-standard DNS.
- **`useAppArmorAnnotation`** in the istio-cni Helm chart, default `true`.
- **`global.enableReaderRBAC`** (default `true`) controls installation of reader RBAC.

### Telemetry

- Service attribute enrichment now follows OpenTelemetry semantic conventions, including support for `app.kubernetes.io/name` and `service.istio.io/canonical-name`.
- New `disableContextPropagation` field in the Telemetry Tracing API, useful for environments where Istio shouldn't propagate trace context.
- Ztunnel Grafana dashboard adds a Resource Usage panel for active TCP connections, open file descriptors, and open sockets per instance.

### Plus much more

- **istioctl** improvements including a `--tls-min-version` plumbed through, sorting fixes for connection output, distroless istioctl image, and zc command refinements
- **CNI** improvements: kubelet probe fix for AWS EKS ambient pods using Security Groups for Pods (branch ENI), gated behind `AMBIENT_ENABLE_AWS_BRANCH_ENI_PROBE` (default on); input validation for `excludeInterfaces`; reconciliation tweaks
- **Wasm**: configurable binary size limit, gzip decompression limit configurable, SSRF protection on Wasm fetches
- **Multicluster**: support for loading remote secrets from a local filesystem path

Read about these and more in the full [release notes](change-notes/).

## Upgrading to 1.30

We would like to hear from you regarding your experience upgrading to Istio 1.30. You can provide feedback in the `#release-1_30` channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.

---
title: Announcing Istio 1.31.0
linktitle: 1.31.0
subtitle: Major Release
description: Istio 1.31 Release Announcement.
publishdate: 2026-08-20
release: 1.31.0
aliases:
    - /news/announcing-1.31
    - /news/announcing-1.31.0
---

We are pleased to announce the release of Istio 1.31. Thank you to all our contributors, testers, users, and enthusiasts for helping us get the 1.31.0 release published!
We would like to thank the Release Managers for this release, **Jacek Ewertowski** from Red Hat, **Jackson Greer** from Microsoft, and **Jianpeng He** from Tetrate.

{{< relnote >}}

{{< tip >}}
Istio 1.31.0 is officially supported on Kubernetes versions 1.32 to 1.36.
{{< /tip >}}

## What's new?

### Agentgateway as a waypoint

Building on the experimental gateway-only support introduced in 1.30, Istio 1.31 adds the `istio-agentgateway-waypoint` GatewayClass for deploying [agentgateway](https://agentgateway.dev) as a waypoint proxy. This release also fixes several issues with ListenerSet handling and mTLS connectivity for agentgateway backends.

### Gateway API: AllowInsecureFallback

Istio now implements the Gateway API `AllowInsecureFallback` feature for client certificate validation. When enabled, the gateway requests a client certificate and attempts to validate it, but still allows the connection if no certificate is presented or validation fails. The `x-forwarded-client-cert` header is populated so backends can perform their own verification.

### Ambient mode enhancements

- **Weighted waypoint canaries.** A service or namespace can now reference both a primary and a canary waypoint via the `istio.io/use-waypoint-canary` and `istio.io/use-waypoint-canary-namespace` labels. The `istio.io/use-waypoint-canary-weight` annotation directs a configurable share of in-mesh connections to the canary waypoint without any client-side changes, enabling gradual rollout of waypoint configuration changes.
- **Multi-cluster stability.** This release includes a large number of ambient mode fixes, particularly around multi-cluster deployments: credential rotation no longer causes stale snapshots or lost endpoint shards, several memory and goroutine leaks in multi-cluster mode have been resolved, and the CNI node agent fixes address a concurrent map-write panic, a file descriptor leak, and a deadlock during pod deletion.

### Traffic management additions

- **Zone-aware load balancing.** A new `zoneAwareLbSetting` field on `DestinationRule.TrafficPolicy.LoadBalancerSettings` and `MeshConfig` lets Envoy automatically route traffic to endpoints in the same availability zone as the downstream proxy, spilling over to other zones only when local capacity is insufficient. This differs from the existing `localityLbSetting` in that zone-level routing is handled automatically by Envoy rather than through static percentages. Cross-region failover ordering and label-based priority tiers can be layered on top.
- **Mesh-wide default traffic policy.** A new `defaultTrafficPolicy` in `MeshConfig` lets mesh administrators set a baseline `connectionPool` and `outlierDetection` that all outbound clusters inherit. A `DestinationRule` that sets one of these blocks overrides the baseline for that block; fields it leaves unset now inherit the mesh baseline instead of Istio's built-in defaults. The baseline `connectionPool` is also applied to inbound clusters and the passthrough cluster.
- **Dynamic forward proxy for unknown hosts.** A new `ALLOW_ANY_DYNAMIC_DNS` outbound traffic policy mode resolves hostnames from the HTTP `Host` header at request time via Envoy's Dynamic Forward Proxy, removing the need for `ServiceEntry` resources for every external destination. Non-HTTP traffic continues to use `PassthroughCluster`. Optional upstream TLS origination can be configured via `meshConfig.outboundTrafficPolicy.tls`.
- **Sidecar egress host exclusion.** `Sidecar` egress listeners now support a `~` prefix on namespace and host entries to subtract from the import set. For example, `*/*` plus `~ns1/*` imports everything except namespace `ns1`. This lets large meshes exclude a few namespaces without enumerating a long allowlist.

### Security

- **FIPS 140-3 compliance policy.** A new `fips-140-3` value for the `COMPLIANCE_POLICY` environment variable enforces TLS 1.2+ with FIPS-compliant cipher suites and P-256/P-384 curves. Go components must be built with Go 1.24+ using `GOFIPS140=v1.0.0`.
- **Trust domain matching in AuthorizationPolicy.** New `trustDomains` and `notTrustDomains` fields on `Source` allow matching or excluding requests based on the trust domain derived from the peer certificate.
- **Strict gateway merging.** `PILOT_ENABLE_STRICT_GATEWAY_MERGING` (enabled by default) prevents cross-namespace merging of Istio Gateway CRDs with managed Gateway API Gateway proxies.
- **XDS API generator authentication.** The MCP config-serving endpoint now requires a verified control-plane identity. Standard sidecar, gateway, and ztunnel traffic is unaffected.

### Installation and operability

- **Kiali** addon updated to v2.26.0.
- **ztunnel CPU-aware worker threads** via `ZTUNNEL_RESOURCE_CPU_LIMIT` and `ZTUNNEL_RESOURCE_CPU_REQUEST` environment variables.
- **`istioctl manifest generate -o`** flag writes generated manifests to a file instead of stdout.
- **`global.readerServiceAccount`** allows binding the `istio-reader` ClusterRole to a custom service account.

### Telemetry

- **Multi-target Prometheus scraping.** A new `prometheus.istio.io/scrape-targets` pod annotation lets users declare multiple application-metrics endpoints per pod as a comma-separated `port:path` list. Pilot-agent scrapes them concurrently and merges the output.
- **Secure metrics ports.** New `ENVOY_SECURE_METRICS_PORT` and `ENVOY_SECURE_MERGED_METRICS_PORT` environment variables expose mTLS-protected Prometheus scrape endpoints on every sidecar proxy.
- **Envoy stats merging toggle.** `PILOT_AGENT_MERGE_ENVOY_STATS` can be set to `false` to disable merging Envoy stats into the agent stats endpoint.

### Plus much more

- **ProxyConfig `connectionSettings`** with an opinionated `EDGE` profile for gateway proxies
- **`MERGE_AND_REPLACE_LIST`** EnvoyFilter patch operation for replacing list fields instead of appending
- **`prefix_rewrite` in `HTTPRedirect`** for prefix-aware path rewriting in redirect rules
- **HTTP/2 keepalive PING settings** configurable on upstream connections through `DestinationRule`
- **`ServiceEntry` visibility control** via `meshConfig.serviceEntryVisibility`
- **`budget_interval`** field in the RetryBudget TrafficPolicy API
- **`istioctl analyze`** warnings for conflicting `ServiceEntry` protocols and outdated Gateway API CRDs

Read about these and more in the full [release notes](change-notes/).

## Upgrading to 1.31

We would like to hear from you regarding your experience upgrading to Istio 1.31. You can provide feedback in the `#release-1_31` channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.

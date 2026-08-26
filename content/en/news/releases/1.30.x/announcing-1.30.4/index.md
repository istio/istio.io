---
title: Announcing Istio 1.30.4
linktitle: 1.30.4
subtitle: Patch Release
description: Istio 1.30.4 patch release.
publishdate: 2026-08-26
release: 1.30.4
aliases:
    - /news/announcing-1.30.4
---

This release contains security fixes. This release note describes what's different between Istio 1.30.3 and 1.30.4.

{{< relnote >}}

## Security update

For more information, see [ISTIO-SECURITY-2026-006](/news/security/istio-security-2026-006).

### Envoy CVEs

- __[CVE-2026-73513](https://nvd.nist.gov/vuln/detail/CVE-2026-73513)__: (CVSS score 7.5): Fixed a heap use-after-free in `oghttp2` when HTTP/2 trailers are received without the `END_STREAM` flag.
- __[CVE-2026-73552](https://nvd.nist.gov/vuln/detail/CVE-2026-73552)__: (CVSS score 7.5): Fixed a bug where `safe_regex` failed open on non-UTF-8 header bytes in negative-match RBAC policies.
- __[CVE-2026-73512](https://nvd.nist.gov/vuln/detail/CVE-2026-73512)__: (CVSS score 7.5): Fixed a use-after-free in the QUIC HTTP datagram handler.
- __[CVE-2026-73547](https://nvd.nist.gov/vuln/detail/CVE-2026-73547)__: (CVSS score 7.5): Fixed abnormal termination in `ext_authz` when handling CONNECT requests without a `:path` header.
- __[CVE-2026-73549](https://nvd.nist.gov/vuln/detail/CVE-2026-73549)__: (CVSS score 5.3): Fixed abnormal termination for scoped IPv6 client addresses with HTTP/3.
- __[CVE-2026-50572](https://nvd.nist.gov/vuln/detail/CVE-2026-50572)__: (CVSS score 5.9): Fixed a use-after-free in the `ext_authz` raw HTTP client.
- __[CVE-2026-73546](https://nvd.nist.gov/vuln/detail/CVE-2026-73546)__: (CVSS score 7.4): Fixed a stored cross-site scripting vulnerability in the HTML stats interface.
- __[CVE-2026-48521](https://nvd.nist.gov/vuln/detail/CVE-2026-48521)__: (CVSS score 5.9): Fixed a null-pointer dereference during ALPN-based HTTP/3 connection-pool selection.
- __[CVE-2026-73551](https://nvd.nist.gov/vuln/detail/CVE-2026-73551)__: (CVSS score 5.3): Fixed URL normalization of dot and dot-dot path segments with parameters.
- __[CVE-2026-73511](https://nvd.nist.gov/vuln/detail/CVE-2026-73511)__: (CVSS score 5.3): Fixed path matching for per-segment parameters.
- __[CVE-2026-73548](https://nvd.nist.gov/vuln/detail/CVE-2026-73548)__: (CVSS score 7.5): Fixed cross-user response poisoning on generic HTTP upgrades.
- __[CVE-2026-73550](https://nvd.nist.gov/vuln/detail/CVE-2026-73550)__: (CVSS score 7.5): Fixed HTTP/2 memory exhaustion via discarded duplicate Host headers.
- __[CVE-2026-73553](https://nvd.nist.gov/vuln/detail/CVE-2026-73553)__: (CVSS score 7.5): Fixed an RBAC bypass via `ignore_path_parameters_in_path_matching`.

### Istio CVEs

- [GHSA-qm8v-g4f9-qhjx](https://github.com/istio/istio/security/advisories/GHSA-qm8v-g4f9-qhjx) (CVSS score 6.8, Moderate): `BackendTLSPolicy` fails open to plaintext on sidecar proxies when its CA reference is unresolved.

### Other Istio Security Fixes

- **Fixed** an `EnvoyFilter` validation gap where an uncapped `proxyVersion` match expression could drive excessive istiod memory and CPU during regex compilation. The match expression is now limited to 1024 characters. **Credit**: This issue was reported by [`Artem Cherezov`](https://github.com/cherez0ff).

## Changes

- **Fixed** a deadlock where the istio-cni node agent pod could fail to start (for example after a node reboot) because the CNI plugin only skipped the Kubernetes client creation for its own agent pod when ambient mode was enabled. The preemptive check now runs in sidecar mode as well, so the agent pod no longer blocks on a kubeconfig it has not written yet. ([Issue #60668](https://github.com/istio/istio/issues/60668))

- **Fixed** a bug where a remote cluster's network gateway could disappear from cross-network routing after credential rotation and not recover until istiod restarted. The in-place registry swap now re-wires the new registry to the aggregate controller's handlers so its future gateway and service events propagate, and reloads gateways once to pick up those discovered during the pre-swap sync. ([Issue #60920](https://github.com/istio/istio/issues/60920))

- **Fixed** an issue in multicluster deployments where rotating a remote cluster's `istio-remote-secret` could permanently wipe endpoint shards for services with stable endpoints in that cluster, making them unreachable across clusters until istiod was restarted. ([Issue #61043](https://github.com/istio/istio/issues/61043))

- **Fixed** a race condition on istiod startup where the readiness probe could report ready before the dedicated injection and validation webhook server (`--httpsAddr`, default `:15017`) was accepting connections, causing intermittent `failed calling webhook` timeouts when creating resources immediately after istiod became ready. This does not affect deployments where webhooks share the main HTTP server (empty `--httpsAddr`). ([Issue #61049](https://github.com/istio/istio/issues/61049))

- **Fixed** an issue where ingress gateways bypassed waypoint proxies for multi-cluster services when remote workloads were on a different network, causing authorization policies to not be enforced. ([Issue #61092](https://github.com/istio/istio/issues/61092))

- **Fixed** an issue where gateway proxy `Deployment` resources could permanently fail to be created during istiod startup. ([Issue #61095](https://github.com/istio/istio/issues/61095))

- **Fixed** an issue where a pod selected by a `ServiceEntry` `workloadSelector` could start up missing that service from its sidecar's inbound configuration. Traffic to the port was not handled as the protocol declared in the `ServiceEntry`, and port-level `PeerAuthentication` was not applied. The pod did not recover on its own; only restarting istiod repaired it. ([Issue #61157](https://github.com/istio/istio/issues/61157))

- **Fixed** an issue where `istio-cni` considered `hostNetwork` pods eligible for ambient enrollment. ([Issue #61168](https://github.com/istio/istio/issues/61168))

- **Fixed** a file descriptor leak in the `istio-cni` node agent: when the `procfs` scan found more than one network namespace for the same pod, the losing candidate's netns file descriptor was dropped without being closed, pinning the namespace in the kernel until garbage collection.

- **Fixed** external SDS providers configured through `extensionProviders` to use the configured service hostname as the gRPC authority.

- **Fixed** a goroutine leak in istiod leader election where every election cycle (leadership lost and re-acquired) leaked one goroutine until process exit. ([Issue #60843](https://github.com/istio/istio/issues/60843))

- **Fixed** an issue where istiod CPU usage increased as the number of `AuthorizationPolicy` resources increased. ([Issue #61254](https://github.com/istio/istio/issues/61254))

- **Fixed** `ListenerSet` conflict resolution for hostname and protocol conflicts. Conflicting listeners are now correctly rejected and `ListenerSet` status conditions report in compliance with Gateway API 1.5. ([PR #60775](https://github.com/istio/istio/pull/60775))

- **Fixed** a bug where a ztunnel reconnect (such as the periodic connection recycle from `keepaliveMaxServerConnectionAge`) triggered a full workload (WDS) push. Istiod now assigns each WDS resource a content-based version and, when a reconnecting client reports the versions it already holds via `initial_resource_versions`, re-sends only resources that changed while the client was disconnected. Older ztunnel versions that do not report versions continue to receive the full set. ([Issue #1966](https://github.com/istio/ztunnel/issues/1966))

- **Fixed** the XDS `api` generator (MCP config serving) to require a verified control-plane identity. Previously, any client that could reach Istiod's XDS port could read Istio config across all namespaces. Default `ENABLE_XDS_API_GENERATOR_AUTH=true`; disable with `ENABLE_XDS_API_GENERATOR_AUTH=false` if needed for compatibility.

- **Fixed** a Gateway API issue where a cross-namespace TLS `certificateRef` or `caCertificateRef` was resolved before the `ReferenceGrant` authorization check, so a listener's `ResolvedRefs` status could reveal whether the referenced `Secret` or `ConfigMap` existed even when no grant permitted the reference. Authorization now runs first, returning `RefNotPermitted` for any cross-namespace reference not permitted by a grant. **Credit**: This issue was reported by Darryl Jaskolski.

- **Fixed** an SSRF gap in istiod's `RequestAuthentication` `jwksUri` fetching. istiod now blocks link-local and known cloud metadata addresses (such as `169.254.169.254`) at the dial level by default and rejects fetched responses that are not a valid JWKS. Private and loopback ranges remain reachable and can be blocked with `BLOCKED_CIDRS_IN_JWKS_URIS`.

- **Fixed** several `sidecar.istio.io/*` annotations (`proxyImage`, `bootstrapOverride`, `logLevel`, `componentLogLevel`, `agentLogLevel`) being interpolated into the sidecar/gateway injection templates without output escaping, which could allow a crafted annotation value to inject additional fields into the generated pod or deployment spec. These annotations are now escaped consistently at every template sink. **Credit**: This vulnerability was discovered and reported by `localhost-detect`.

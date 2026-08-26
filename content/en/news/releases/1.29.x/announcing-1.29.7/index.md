---
title: Announcing Istio 1.29.7
linktitle: 1.29.7
subtitle: Patch Release
description: Istio 1.29.7 patch release.
publishdate: 2026-08-26
release: 1.29.7
aliases:
    - /news/announcing-1.29.7
---

This release contains security fixes. This release note describes what's different between Istio 1.29.6 and 1.29.7.

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

- __[CVE-XXXX-XXXXX](https://nvd.nist.gov/vuln/detail/CVE-XXXX-XXXXX)__ / [GHSA-qm8v-g4f9-qhjx](https://github.com/istio/istio/security/advisories/GHSA-qm8v-g4f9-qhjx): (CVSS score 6.8): Fixed `BackendTLSPolicy` failing open to plaintext on sidecar proxies when its CA certificate reference is unresolved.

### Other Istio Security Fixes

- **Fixed** an `EnvoyFilter` validation gap where an uncapped `proxyVersion` match expression could drive excessive istiod memory and CPU during regex compilation. The match expression is now limited to 1024 characters. **Credit**: This issue was reported by [`Artem Cherezov`](https://github.com/cherez0ff).

## Changes

- **Upgraded** version of `nftables` used by Istio distroless images. The `nftables` version was previously pinned to 1.1.1 to avoid a bug that could cause older versions of `nftables` on Kubernetes nodes to crash after Istio used a newer version packaged in its images on the same node. Major Linux distributions have been informed of the issue and have released fixes. As a result, Istio is removing the `nftables` version pinning. Users are advised to update the `nftables` package on their nodes to the latest available version to ensure that the fixed version is installed. If you continue to experience `nftables` crashes on your nodes, downgrade to an older version of Istio and contact your node OS provider to request that the fix be backported to your OS version. ([Issue #58492](https://github.com/istio/istio/issues/58492))

- **Fixed** a race condition on istiod startup where the readiness probe could report ready before the dedicated injection and validation webhook server (`--httpsAddr`, default `:15017`) was accepting connections, causing intermittent `failed calling webhook` timeouts when creating resources immediately after istiod became ready. This does not affect deployments where webhooks share the main HTTP server (empty `--httpsAddr`). ([Issue #61049](https://github.com/istio/istio/issues/61049))

- **Fixed** an issue where ingress gateways bypassed waypoint proxies for multi-cluster services when remote workloads were on a different network, causing authorization policies to not be enforced. ([Issue #61092](https://github.com/istio/istio/issues/61092))

- **Fixed** an issue where gateway proxy `Deployment` resources could permanently fail to be created during istiod startup. ([Issue #61095](https://github.com/istio/istio/issues/61095))

- **Fixed** an issue where `istio-cni` considered `hostNetwork` pods eligible for ambient enrollment. ([Issue #61168](https://github.com/istio/istio/issues/61168))

- **Fixed** a file descriptor leak in the `istio-cni` node agent: when the `procfs` scan found more than one network namespace for the same pod, the losing candidate's netns file descriptor was dropped without being closed, pinning the namespace in the kernel until garbage collection.

- **Fixed** a bug where the `istio-cni` node agent could pair an ambient pod with another pod's network namespace when a third-party process was inside that namespace during a scan, which could cause traffic to be proxied with the wrong identity. The node agent now verifies that a namespace holds one of the pod's IPs before enrolling the pod. ([Issue #61211](https://github.com/istio/istio/issues/61211))

- **Fixed** an issue where istiod permanently retained a copy of every workload resource name for each Envoy MDS (WDS, used for telemetry metadata lookups) connection that sent `initial_resource_versions`.

- **Fixed** a bug where a ztunnel reconnect (such as the periodic connection recycle from `keepaliveMaxServerConnectionAge`) triggered a full workload (WDS) push. Istiod now assigns each WDS resource a content-based version and, when a reconnecting client reports the versions it already holds via `initial_resource_versions`, re-sends only resources that changed while the client was disconnected. Older ztunnel versions that do not report versions continue to receive the full set. ([Issue #1966](https://github.com/istio/ztunnel/issues/1966))

- **Fixed** a Gateway API issue where a cross-namespace TLS `certificateRef` or `caCertificateRef` was resolved before the `ReferenceGrant` authorization check, so a listener's `ResolvedRefs` status could reveal whether the referenced `Secret` or `ConfigMap` existed even when no grant permitted the reference. Authorization now runs first, returning `RefNotPermitted` for any cross-namespace reference not permitted by a grant. **Credit**: This issue was reported by Darryl Jaskolski.

- **Fixed** an SSRF gap in istiod's `RequestAuthentication` `jwksUri` fetching. istiod now blocks link-local and known cloud metadata addresses (such as `169.254.169.254`) at the dial level by default and rejects fetched responses that are not a valid JWKS. Private and loopback ranges remain reachable and can be blocked with `BLOCKED_CIDRS_IN_JWKS_URIS`.

- **Fixed** the XDS `api` generator (MCP config serving) to require a verified control-plane identity. Previously any client that could reach istiod's XDS port could read Istio config across all namespaces. Disable with `ENABLE_XDS_API_GENERATOR_AUTH=false` if needed for compatibility.

- **Fixed** several `sidecar.istio.io/*` annotations (`proxyImage`, `bootstrapOverride`, `logLevel`, `componentLogLevel`, `agentLogLevel`) being interpolated into the sidecar/gateway injection templates without output escaping, which could allow a crafted annotation value to inject additional fields into the generated pod or deployment spec. These annotations are now escaped consistently at every template sink. **Credit**: This vulnerability was discovered and reported by `localhost-detect`.

- **Fixed** goroutine and memory leaks in istiod in ambient multi-cluster mode when remote clusters are removed or updated. The internal collections built for each remote cluster did not release the event handlers they had registered on their inputs when torn down, causing goroutines and memory to accumulate over time as clusters were removed or reconfigured. ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Fixed** a goroutine leak in istiod leader election where every election cycle (leadership lost and re-acquired) leaked one goroutine until process exit. ([Issue #60843](https://github.com/istio/istio/issues/60843))

- **Fixed** an issue where istiod CPU usage increased as the number of `AuthorizationPolicy` resources increased. ([Issue #61254](https://github.com/istio/istio/issues/61254))

- **Fixed** generated Gateway `Service`s being rejected when two listener names sanitize to the same Service port name (names differing only by periods versus dashes, or only past the 63-character limit), which blocked every unpublished port on the Gateway. Colliding port names are now disambiguated with the listener's port number.

- **Improved** performance when fetching `PeerAuthentication` resources for a given workload.

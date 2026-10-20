---
title: Announcing Istio 1.29.9
linktitle: 1.29.9
subtitle: Patch Release
description: Istio 1.29.9 patch release.
publishdate: 2026-10-15
release: 1.29.9
aliases:
    - /news/announcing-1.29.9
---

This release contains security fixes. This release note describes what's different between Istio 1.29.8 and 1.29.9. This is the final 1.29 release, as [1.29 reached end of life](/news/support/announcing-1.29-eol/) on October 15, 2026. We encourage you to upgrade to a supported release.

{{< relnote >}}

## Security update

For more information, see [ISTIO-SECURITY-2026-007](/news/security/istio-security-2026-007).

### Envoy CVEs

- __[GHSA-8vc2-jrm4-835w](https://github.com/envoyproxy/envoy/security/advisories/GHSA-8vc2-jrm4-835w)__: (CVSS score 7.5): Fixed an unauthenticated remote crash in the OAuth2 HTTP filter on a CONNECT request without a `:path` header.
- __[GHSA-47vj-9r25-wv5j](https://github.com/envoyproxy/envoy/security/advisories/GHSA-47vj-9r25-wv5j)__: (CVSS score 6.5): Fixed a crash in the `api_key_auth` HTTP filter on a CONNECT request without a `:path` header.
- __[CVE-2026-111497](https://nvd.nist.gov/vuln/detail/CVE-2026-111497)__: Fixed a vulnerability in the Brotli compression library used by Envoy. Users who enable Brotli decompression, for example with an `EnvoyFilter`, should upgrade.

### Istio CVEs

- __[GHSA-w44g-8m76-8gc5](https://github.com/istio/istio/security/advisories/GHSA-w44g-8m76-8gc5)__ (CVSS score 7.4, High): `AuthorizationPolicy` method rules are bypassed over HTTP/2 by changing the case of the method. **Credit**: This vulnerability was discovered and reported by [izzy0101010101](https://github.com/izzy0101010101).
- __[GHSA-7p2q-4xvg-vxc6](https://github.com/istio/istio/security/advisories/GHSA-7p2q-4xvg-vxc6)__ (CVSS score 7.7, High): istiod crashes in ambient mode when a `ServiceEntry` or other service claims the address of an IP-addressed waypoint. **Credit**: This vulnerability was discovered and reported by [yshch](https://github.com/yshch).

### Other Istio Security Fixes

- **Fixed** `istioctl` skipping verification of the istiod certificate when connecting to XDS with a service account token (`istioctl proxy-status`, `istioctl x internal-debug`, and `--xds-address` in general). istioctl now verifies the server against the Istio root certificate from the `istio-ca-root-cert` configmap and the expected server name: `--authority` if set, the host of `--xds-address` if it is a DNS name, or `istiod.<istio-namespace>.svc` when connecting to an IP address or localhost. Pass `--insecure` (or set `ISTIOCTL_INSECURE=true`) to explicitly skip verification. **Credit**: This issue was reported by [Leon Zlobecki](https://leonz.is). ([Issue #41937](https://github.com/istio/istio/issues/41937))

- **Fixed** `istioctl manifest translate` writing unquoted values from IstioOperator input (such as namespace and release name) into generated install shell scripts. Crafted values could inject additional shell commands when those scripts were run. Arguments are now escaped with `shellescape.Quote`. **Credit**: This vulnerability was discovered and reported by OpenSec Intelligence.

- **Fixed** a panic in istiod when the OIDC/JWT authenticator received a token with a malformed `sub` claim. The subject is now validated to have exactly the `system:serviceaccount:<namespace>:<serviceaccount>` form before use. **Credit**: This issue was reported by Kaizhe Huang.

- **Fixed** `CreateCertificate` returning raw Kubernetes API error text to callers on the experimental Kubernetes CSR RA path (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`), which leaked CSR names, signer names, and istiod's identity. The full error is now logged server-side only. Reported by Juno Im.

- **Fixed** the Kubernetes CSR watch loop using an abandoned `time.After` timer that could leave a goroutine running past request completion on the experimental Kubernetes CSR RA path (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`). The loop is now bounded by a properly scoped `context.WithTimeout` and is reliably torn down on timeout or cancellation. Reported by Juno Im.

- **Fixed** client-requested `ValidityDuration` being accepted up to `MAX_WORKLOAD_CERT_TTL` (default `90d`) on the experimental Kubernetes CSR RA path (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`). A new `MAX_RA_WORKLOAD_CERT_TTL` environment variable (default `48h`) now caps the TTL, limiting the blast radius of a stolen istio-token. Deployments that legitimately requested certificates with TTL > `48h` via this path should raise `MAX_RA_WORKLOAD_CERT_TTL` after upgrade. Reported by Juno Im.

- **Fixed** the Wasm OCI image fetcher deciding to retry a failed HTTPS fetch over plaintext HTTP based on the error returned by the registry. Since the registry is untrusted input, a MITM or malicious registry could trigger this fallback on demand to force plaintext transport and, without an optional module digest pinned, serve an arbitrary Wasm binary. The plaintext retry is now only attempted for registries the operator has explicitly allowlist via `WASM_INSECURE_REGISTRIES`. **Credit**: This vulnerability was discovered and reported by Adam Korczynski.

- **Fixed** istiod debug endpoints (`/debug/config_dump`, `/debug/edsz`, and the XDS `istio.io/debug/config_dump` type) matching `proxyID` as a substring, which let a caller read the config of other proxies in its own namespace by passing a partial ID. `proxyID` must now be the exact `<pod>.<namespace>` (or full connection ID); short forms such as `proxyID=istio-ingressgateway` no longer match. **Credit**: This issue was reported by 박현범.

- **Improved** Added `PILOT_ENABLE_STRICT_GATEWAY_MERGING` to prevent cross-namespace merging of Istio Gateways with managed `GatewayAPI` Gateways. When enabled, Istio Gateway CRDs from different namespaces will not be merged with managed `GatewayAPI` Gateway proxies. Unmanaged (manual deployment) `GatewayAPI` Gateways are not affected. This is disabled by default in this release; set `PILOT_ENABLE_STRICT_GATEWAY_MERGING` to `true` to enable.

## Changes

- **Fixed** an `HTTPRoute` rule with several `InferencePool` `backendRefs` configuring only one endpoint picker. The picker of the last `backendRef` listed scored every request on the rule, so the other pools' pickers were never invoked, and a pool with no ready endpoints failed the whole rule rather than its own weighted share. Each pool now gets its own picker, attached to its own weighted cluster. ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Fixed** two `HTTPRoute`s sharing a `rules[].name` on the same gateway overwriting each other's endpoint picker. Rule names only have to be unique within one `HTTPRoute`, but the pickers were keyed by name across all of them, so a route could be served by another route's picker. Pickers are now resolved per `backendRef`, so a shared name no longer moves one route's picker onto another. ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Fixed** a route rule losing its `InferencePool` endpoint picker when it also carried a CORS filter. Both are written into the same per-filter configuration, and the CORS path replaced the map rather than adding to it. ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Fixed** sidecar proxy UID/GID resolution on OpenShift for workloads bound to a custom `SecurityContextConstraint` with a narrow or explicitly-configured UID range, which the namespace's preallocated UID range annotation does not advertise. ([Issue #61791](https://github.com/istio/istio/issues/61791))

- **Added** a validation warning for `ServiceEntry` addresses that are catch-all (`0.0.0.0`, `::`), have an unspecified network (`0.0.0.0/N`, `::/N`), or are a CIDR with a prefix shorter than `/8`. A `ServiceEntry` like this with `resolution: NONE` and the default `exportTo` can make every sidecar in the mesh pass through traffic on its ports, bypassing `outboundTrafficPolicy` `REGISTRY_ONLY`. Use a narrower CIDR and `exportTo: ["."]`. For egress enforcement, use an egress gateway with a NetworkPolicy. ([Issue #62124](https://github.com/istio/istio/issues/62124))

- **Fixed** an issue where the pre-marshaled workload used for change detection and versioning in ambient was not stable when a workload had more than one service, which made unchanged workloads look modified on every recompute and prevented unchanged workloads from being skipped when a client reconnected.

- **Fixed** a memory and goroutine leak in Istiod ambient multi-cluster mode where the per-cluster node locality collections were scoped to the process lifetime instead of the cluster lifetime, so they were never torn down when a remote cluster was removed. ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Fixed** a bug where an internal listener was incorrectly created when the listener is of HTTPS or TLS but without a TLS section defined. A following version of the Gateway API will [prevent](https://github.com/kubernetes-sigs/gateway-api/pull/4788) this combination of inputs from ever reaching a controller. ([Issue #60562](https://github.com/istio/istio/issues/60562))

- **Fixed** a memory leak in ambient multi-cluster mode where collections were registered with the krt debugger but never unregistered when a remote cluster was removed or its configuration changed, causing debugger registrations to accumulate over time. ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Fixed** Istio components hanging indefinitely when a Kubernetes API request gets no response, for example when a load balancer or proxy silently drops the return path. Previously such a request could stay open forever, stalling the controller that issued it until the process restarted. Requests now time out on the client side, so a stuck request is canceled and the component recovers on its own. Each timeout is logged as a warning and counted by the `kube_client_deadline_fired_total` metric. The timeouts can be tuned with `ISTIO_KUBE_HEADER_TIMEOUT` (default `90s`) and `ISTIO_KUBE_REQUEST_TIMEOUT` (default `15m`); set either to `0` to restore the previous unbounded behavior.

- **Fixed** ztunnel crash-looping with exit code 133 (`SIGTRAP`) on arm64 nodes whose CPUs provide the `RNDR` instruction, such as GKE Axion, when the hardware random number generator reported a transient failure. `aws-lc-rs` is updated to 1.18.2, which retries the read instead of aborting. ([Issue #2072](https://github.com/istio/ztunnel/issues/2072))

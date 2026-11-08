---
title: Announcing Istio 1.30.8
linktitle: 1.30.8
subtitle: Patch Release
description: Istio 1.30.8 patch release.
publishdate: 2026-11-06
release: 1.30.8
aliases:
    - /news/announcing-1.30.8
---

This release contains security fixes. This release note describes what's different between Istio 1.30.7 and 1.30.8.

{{< relnote >}}

## Security update

For more information, see [ISTIO-SECURITY-2026-009](/news/security/istio-security-2026-009).

### Istio CVEs

- __[GHSA-rr2c-p22p-6r9r](https://github.com/istio/istio/security/advisories/GHSA-rr2c-p22p-6r9r)__ (CVSS score 8.2, High): In ambient mode, an operator-precedence error let a port-level `STRICT` `PeerAuthentication` be skipped when the workload mode was `PERMISSIVE` or `DISABLE` under a mesh-wide `STRICT` policy, allowing plaintext traffic to reach a port that required mTLS. **Credit**: This vulnerability was discovered and reported by Ravikanth Reddy.
- __[GHSA-7m6f-j3gp-2r53](https://github.com/istio/istio/security/advisories/GHSA-7m6f-j3gp-2r53)__ (CVSS score 6.5, Moderate): An `AuthorizationPolicy` `when` condition on `request.headers[:authority]` or `request.headers[host]` was matched case-sensitively, so a request with a differently-cased host could bypass it. These conditions are now matched case-insensitively, the same as `hosts`. **Credit**: This vulnerability was discovered and reported by [@akoul](https://github.com/akoul).
- __[GHSA-cxwg-46mx-q8hf](https://github.com/istio/istio/security/advisories/GHSA-cxwg-46mx-q8hf)__ (CVSS score 7.4, High): A new inbound connection reusing the 4-tuple of a torn-down connection could bypass the sidecar proxy by matching a stale conntrack `ESTABLISHED` entry. A SYN-only rule is now evaluated ahead of the `ESTABLISHED` divert rule in both iptables and nftables modes. **Credit**: This vulnerability was discovered and reported by [@ramaraochavali](https://github.com/ramaraochavali), [@akshayreddyb](https://github.com/akshayreddyb), [@Pawan-Bishnoi](https://github.com/Pawan-Bishnoi), and [@deveshkandpal1224](https://github.com/deveshkandpal1224).
- __[GHSA-635j-qv98-9275](https://github.com/istio/istio/security/advisories/GHSA-635j-qv98-9275)__ (CVSS score 7.7, High): Any workload with a mesh identity could crash istiod by sending an `istio.io/debug` xDS request whose resource name fails URL parsing, leaving the control plane in a crash loop for the whole mesh. The request is now rejected with `InvalidArgument`. **Credit**: This vulnerability was discovered and reported by Alon Lerner of Checkmarx Research.
- __[GHSA-8jw7-82jp-wr2c](https://github.com/istio/istio/security/advisories/GHSA-8jw7-82jp-wr2c)__ (CVSS score 6.3, Moderate): In ambient mode, an `AuthorizationPolicy` with an empty `to` or `from` entry that was not rejected by the validating webhook caused istiod to crash and crash-loop until the policy was removed, stopping config distribution for the whole mesh. Such entries are now treated as an empty `operation` or `source`, matching the sidecar behavior. **Credit**: This vulnerability was discovered and reported by [@r0binak](https://github.com/r0binak).
- __[GHSA-gf6w-6mxv-5fj4](https://github.com/istio/istio/security/advisories/GHSA-gf6w-6mxv-5fj4)__ (CVSS score 6.3, Moderate): In multicluster installations, a proxy could claim another cluster's `CLUSTER_ID` and receive that cluster's `kubernetes://` secrets over SDS. istiod no longer accepts a node metadata `CLUSTER_ID` that differs from the cluster the proxy's token was validated against. **Credit**: This vulnerability was discovered and reported by Yonghwa Lee (Xint by Theori).
- __[GHSA-77vw-rg85-wx5x](https://github.com/istio/istio/security/advisories/GHSA-77vw-rg85-wx5x)__ (CVSS score 6.5, Moderate): ztunnel panicked when parsing a 55-byte `traceparent` header that did not contain four dash-separated fields, terminating the inbound HBONE connection task and dropping every stream multiplexed on that connection. Headers with the correct length but an invalid field layout were also accepted instead of rejected. Invalid `traceparent` headers are now ignored and a new trace ID is generated. **Credit**: This vulnerability was discovered and reported by [@RaphaelFakhri](https://github.com/RaphaelFakhri).
- __[GHSA-9gqj-583v-mpqp](https://github.com/istio/istio/security/advisories/GHSA-9gqj-583v-mpqp)__ (CVSS score 5.6, Moderate): `AuthorizationPolicy` `ipBlocks`, `notIpBlocks` and the `source.ip` condition on ambient waypoints, and on sidecars receiving HBONE traffic, matched the Envoy internal listener address instead of the client IP, so `DENY` rules on these fields could fail open.

### Other Istio Security Fixes

- **Fixed** the JWKS resolver's periodic background refresh caching a fetched response without validating that it looks like a JWKS. The synchronous fetch path already rejected a response that isn't shaped like a JWKS (`{"keys": [...]}`), preventing a `RequestAuthentication` `jwksUri` pointed at an unintended internal endpoint from having its response cached and served back as if it were a JWKS. The background refresh path now applies the same check. **Credit**: This issue was reported by Anthropic and Ada Logics.

## Changes

- **Fixed** an istiod panic when `outlierDetection` was applied to a dynamic forward proxy (DFP) wildcard cluster. ([Issue #61450](https://github.com/istio/istio/issues/61450))

- **Fixed** an issue where the `istio-cni` Helm chart did not respect the value set for `istioOwnedCNIConfigFileName`.

- **Fixed** an issue where updates to the `istio-cni` config via the Helm chart did not restart `istio-cni` to pick up the new values.

- **Fixed** an issue where, when uninstalling the `istio-cni` Helm chart, the owned `istio-cni` config was not removed or the primary CNI config did not have the `istio-cni` plugin removed.

- **Fixed** an issue where, when enabling the owned `istio-cni` config, the primary CNI config was not cleaned up.

- **Fixed** an issue where, when changing the owned `istio-cni` config filename, the previous filename was not removed. ([Issue #61890](https://github.com/istio/istio/issues/61890))

- **Fixed** the `source_app` and `destination_app` metric labels to use the `app` pod label when a pod also has `app.kubernetes.io/name`. Since 1.29.1 they had used `app.kubernetes.io/name`, which is a regression from the intended behavior. ([Issue #62280](https://github.com/istio/istio/issues/62280))

- **Fixed** a situation where fetching the JWKS could block xDS generation. ([Pull Request #62486](https://github.com/istio/istio/pull/62486))

- **Fixed** `AuthorizationPolicy` `ipBlocks` and `notIpBlocks` matching on waypoint and sidecar HBONE internal listeners to use the downstream client's direct remote IP address instead of the internal Envoy address. ([Issue #62522](https://github.com/istio/istio/issues/62522))

- **Fixed** an issue where `istio-cni` skipped cleanup for an ambient pod deleted together with its namespace, leaving its ztunnel proxy and host probe ipset entry behind.

- **Fixed** an issue where a metadata-only update to an `EndpointSlice`, such as a GitOps tool writing an annotation, triggered an EDS push, and for headless `Services` with non-HTTP ports a push to every proxy, even though the endpoints were unchanged.

- **Fixed** `istiod` only tolerating the default `cni.istio.io/not-ready` taint. When `taint.name` is set to a custom taint, the `istiod` deployment now tolerates that taint, so `istiod` can be scheduled onto nodes that still carry it. ([Issue #52073](https://github.com/istio/istio/issues/52073))

- **Fixed** an issue where a metadata-only update to an Istio config resource, such as a GitOps tool writing an annotation, triggered a push whenever the resource carried any `istio.io` label or annotation, for example `istio.io/rev`. A push is now triggered only when the spec or the value of an `istio.io` label or annotation changes.

- **Fixed** a regression where a `Telemetry` resource in a waypoint's own namespace, selected by `targetRefs` or `selector`, was not applied when the waypoint served a `Service` in a different namespace. Access logging, metrics, and tracing configured this way were silently dropped for every cross-namespace `Service` the waypoint handled. ([Issue #61538](https://github.com/istio/istio/issues/61538))

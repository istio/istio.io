---
title: Announcing Istio 1.30.1
linktitle: 1.30.1
subtitle: Patch Release
description: Istio 1.30.1 patch release.
publishdate: 2026-06-04
release: 1.30.1
aliases:
    - /news/announcing-1.30.1
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.30.0 and 1.30.1.

{{< relnote >}}

## Security Update

- [CVE-2026-47774](https://github.com/envoyproxy/envoy/security/advisories/GHSA-22m2-hvr2-xqc8) (CVSS score 7.5, High): An unauthenticated remote attacker can cause denial of service by exhausting memory in the Envoy process. Cookie header bytes are not fully accounted for during request header size validation, and HPACK header block limits are enforced on encoded bytes without a corresponding limit on total decoded header size, allowing attackers to trigger excessive memory consumption through specially crafted HTTP/2 requests.

## Changes

- **Updated** Kiali addon to version `v2.26.0`.

- **Added** support for excluding policy configuration from Istio when the
  `istio.io/ignore-policy-attachment` annotation is set to `"true"` on a
  `BackendTLSPolicy` or `XBackendTrafficPolicy` object. This allows users to
  prevent specific policies from being translated into Istio configuration
  when the policy is intended for a different gateway controller than Istio.
  ([Issue #60122](https://github.com/istio/istio/issues/60122))

- **Added** an initialization check that verifies the bundled `nft` binary
  supports JSON output. The native nftables backend requires JSON to read
  configuration during pod removal. On hosts whose `nft` binary doesn't
  support JSON, those calls fail with `Error: JSON support not compiled-in` on
  every removal, and the CNI agent retries indefinitely. The new check detects
  this error at startup and falls back to the iptables backend.
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **Added** `istioctl analyze` check `IST0176` that flags Gateway API CRDs installed at a
  version below the minimum required by the current Istio version. Resources backed by such
  CRDs are silently filtered by istiod, which previously made it hard to discover TLS
  passthrough breakage after upgrading to Istio 1.30 with stale Gateway API CRDs.

- **Fixed** `BackendTLSPolicy` conflict resolution on Gateway API.
  ([Issue #57817](https://github.com/istio/istio/issues/57817))

- **Fixed** an issue where HTTPS listeners defined via `ListenerSet` failed to deliver TLS certificates when the parent Gateway used manual deployment.
  ([Issue #59535](https://github.com/istio/istio/issues/59535))

- **Fixed** an issue where HTTPRoute and GRPCRoute filters with invalid header values were silently dropped from the Envoy config instead of reporting an invalid filter status.
  ([Issue #59933](https://github.com/istio/istio/issues/59933))

- **Fixed** an issue where multi-network ambient did not route to the waypoint
  when the ingress on one network called a service on a different network, even
  when the Service was configured with `istio.io/ingress-use-waypoint`.

- **Fixed** an issue where `consistentHash` load balancing in `DestinationRule` would not send traffic
to new endpoints after scaling, due to an Envoy regression (`envoyproxy/envoy#45212`) where the
`RING_HASH` ring was not rebuilt on endpoint changes during batched updates.
  ([Issue #60312](https://github.com/istio/istio/issues/60312))

- **Fixed** a fatal `concurrent map writes` panic in the istio-cni agent when
two pods were added to the ambient mesh on the same node at the same time.
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **Fixed** an ambient mode bug where a single Service combining `publishNotReadyAddresses: true` with a `PreferSameZone` or `PreferSameNode` traffic distribution caused ztunnel to receive `healthPolicy: AllowAll` for every other Service using the same traffic-distribution preset, leading to traffic being routed to not-ready endpoints cluster-wide.
  ([Issue #60422](https://github.com/istio/istio/issues/60422))

- **Fixed** an issue where pilot generated configuration for the agentgateway ignored
  `ListenerSet` resources and routes attached to them. Pilot now correctly includes
  `ListenerSet` resources in agentgateway configuration, enabling agentgateway in Istio
  to handle `ListenerSet` resources properly.

- **Fixed** `ListenerSet` status reporting when `ListenerSet` is not allowed by the parent
  Gateway resource for agentgateway. When `ListenerSet` is not allowed by the parent Gateway,
  the `Accepted` condition status is now correctly reported as `False`. Additionally, given
  that the `ListenerSet` feature is not experimental as of Gateway API `v1.5.0`, it is no
  longer guarded by the `PILOT_ENABLE_ALPHA_GATEWAY_API` feature flag.

- **Fixed** the external SDS provider for gateways to use the credential name (after stripping the `sds://`
  prefix) as the SDS resource name instead of the provider name. This allows multiple gateways using the
  same SDS provider to request different certificates. For mutual TLS, the CA certificate resource name
  is correctly derived as `<credential-name>-cacert`. When neither a UDS socket nor an SDS extension
  provider is configured, the gateway now falls back to fetching certificates via ADS (Kubernetes Secrets)
  instead of failing silently.
  ([Issue #57080](https://github.com/istio/istio/issues/57080))

- **Fixed** a deadlock in the multicluster `ClusterStore` where `AllReady` could recursively acquire the store `RWMutex` for read via `triggerRecomputeOnSync` -> `GetByID` while a writer was waiting, blocking further reads and writes against the store.

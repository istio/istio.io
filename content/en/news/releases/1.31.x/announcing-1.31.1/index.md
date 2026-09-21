---
title: Announcing Istio 1.31.1
linktitle: 1.31.1
subtitle: Patch Release
description: Istio 1.31.1 patch release.
publishdate: 2026-09-21
release: 1.31.1
aliases:
    - /news/announcing-1.31.1
---

This release contains bug fixes to improve robustness. This release note describes what's different between Istio 1.31.0 and 1.31.1.

{{< relnote >}}

## Security Update

### Istio CVEs

- __[GHSA-qm8v-g4f9-qhjx](https://github.com/istio/istio/security/advisories/GHSA-qm8v-g4f9-qhjx)__ (CVSS score 6.8, Moderate): `BackendTLSPolicy` fails open to plaintext on sidecar proxies when its CA reference is unresolved.

## Changes

- **Improved** performance when fetching `PeerAuthentications` for a given workload.

- **Updated** Kiali addon to version v2.31.0.

- **Fixed** an issue in ambient mode where the CNI node agent auto-detected iptables backend
  (`legacy` vs `nft`) could flip between agent restarts, causing duplicate
  redirect rules to be written into already-enrolled pods.
  ([Issue #61020](https://github.com/istio/istio/issues/61020))

- **Fixed** the ability to clear the Certificate Revocation List (CRL) by either specifying an
  empty string as the `ca-crl.pem` or removing it.
  ([Issue #61073](https://github.com/istio/istio/issues/61073))

- **Fixed** the JWKS resolver forcing all public-key fetches to HTTP/1.1. The custom
  `TLSClientConfig` and `DialContext` used for TLS pinning and CIDR blocking caused Go's
  `net/http` to disable automatic HTTP/2, so ALPN never negotiated h2. HTTP/2 is now
  re-enabled (matching `http.DefaultTransport`), fixing JWKS fetches that fail over HTTP/1.1
  through some HTTP CONNECT proxies.
  ([Issue #61250](https://github.com/istio/istio/issues/61250))

- **Fixed** an issue where istiod CPU usage increased as the number of `AuthorizationPolicies` increased.
  ([Issue #61254](https://github.com/istio/istio/issues/61254))

- **Fixed** `ALLOW_ANY_DYNAMIC_DNS` traffic failing in IPv6-only clusters because Envoy used the
  IPv4 loopback address to reach the DNS proxy.
  ([Issue #61330](https://github.com/istio/istio/issues/61330))

- **Fixed** an issue where istiod repeatedly serialized the same workload when
  pushing workload metadata to Envoy proxies.
  ([Issue #61502](https://github.com/istio/istio/issues/61502))

- **Fixed** an issue where Envoy proxies subscribed to Workload metadata discovery (MDS) did not
  receive incremental workload updates for Address-only changes when
  `AMBIENT_SCOPED_ADDRESS_PUSHES` was enabled (the default).

- **Fixed** an issue where an agentgateway waypoint that a service referenced only as its canary,
  via the `istio.io/use-waypoint-canary` label, was not programmed with the routes and policies
  attached to that service. Connections shifted to the canary waypoint were rejected, because the
  waypoint had no configuration for the service it was fronting.
  ([Issue #61036](https://github.com/istio/istio/issues/61036))

- **Fixed** a memory leak affecting Istiod ambient multi-cluster mode where rotating a remote cluster's
  credentials leaked that cluster's entire cached state.
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Fixed** `istioctl analyze` building Kubernetes clients directly from `istio-system`
  multicluster secrets without sanitizing the kubeconfig, which could allow a crafted
  secret to run an `exec` credential plugin (or read local files via other unsafe auth
  fields) on the machine running `istioctl`. The kubeconfig is now sanitized the same
  way istiod already sanitizes these secrets.

  **Credit**: This vulnerability was discovered and reported by Adam Korczynski.

- **Fixed** the `istio.io/use-waypoint-canary` label bypassing the `serviceEntryVisibility`
  NAMESPACE isolation: a NAMESPACE-visibility `ServiceEntry` could route its canary share of
  traffic through a waypoint in another namespace. The canary waypoint is now subject to the
  same cross-namespace refusal as the primary.

  **Credit**: This issue was reported by Raphael Zanarelli.

- **Fixed** the `default` chart's `ValidatingWebhookConfiguration` still hardcoding `failurePolicy: Ignore`,
  which caused the same field manager conflict on `helm upgrade` with server-side apply that was
  previously fixed for the `base` and `istiod` charts.
  ([Issue #61613](https://github.com/istio/istio/issues/61613))

- **Fixed** an issue where istiod permanently retained a copy of every workload resource name for each
  envoy MDS (WDS, used for telemetry metadata lookups) connection that sent `initial_resource_versions`.

- **Fixed** the `sidecar.istio.io/statsFlushInterval` annotation producing an invalid Envoy
  bootstrap for values of one minute or more, and for sub-second values, which prevented the
  proxy from starting.

- **Fixed** the `sidecar.istio.io/statsEvictionInterval` annotation silently truncating
  sub-second precision.

- **Fixed** a Gateway API issue where a cross-namespace TLS `certificateRef` or
  `caCertificateRef` was resolved before the `ReferenceGrant` authorization
  check, so a listener's `ResolvedRefs` status could distinguish whether the
  referenced Secret or ConfigMap existed even when no grant permitted the
  reference. Authorization now runs first, returning `RefNotPermitted` for any
  ungranted cross-namespace reference.

  **Credit**: This issue was reported by Darryl Jaskolski.

- **Fixed** an SSRF gap in istiod's `RequestAuthentication` `jwksUri` fetching. istiod now
  blocks link-local and known cloud metadata addresses (such as `169.254.169.254`) at the dial
  level by default and rejects fetched responses that are not a valid JWKS. Private and loopback
  ranges remain reachable and can be blocked with `BLOCKED_CIDRS_IN_JWKS_URIS`.

- **Fixed** a memory leak in ambient multi-cluster mode where collections were registered with the
  krt debugger but never unregistered when a remote cluster was removed or its configuration changed,
  causing debugger registrations to accumulate over time.
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Fixed** listener conflict tracking treating a `Gateway` and a `ListenerSet` with the same
  namespace and name as the same object, which caused a conflict recorded for one to mark the
  other's winning listener as `Conflicted` and stop it from being programmed.

- **Fixed** ServiceEntries with a present but empty workload selector incorrectly matching all workloads in their namespace.

- **Fixed** a pod in a remote cluster, selected by a `ServiceEntry` may not have been recomputed
  when it became an endpoint of that service. The recompute was addressed to the cluster istiod
  runs in rather than the cluster the pod belongs to.

- **Fixed** a WorkloadEntry selected by a `Service` not having its corresponding proxy recomputed
  when it became an endpoint of that service.

- **Fixed** several `sidecar.istio.io/*` annotations (`proxyImage`, `bootstrapOverride`,
  `logLevel`, `componentLogLevel`, `agentLogLevel`) being interpolated into the sidecar/gateway
  injection templates without output escaping, which could allow a crafted annotation value to
  inject additional fields into the generated pod or deployment spec. These annotations are now
  escaped consistently at every template sink.

  **Credit**: This vulnerability was discovered and reported by localhost-detect.

- **Fixed** `observedGeneration` getting stuck on a stale value when a resource is modified again
  while an earlier status write is still queued.

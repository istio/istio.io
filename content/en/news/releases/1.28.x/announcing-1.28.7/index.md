---
title: Announcing Istio 1.28.7
linktitle: 1.28.7
subtitle: Patch Release
description: Istio 1.28.7 patch release.
publishdate: 2026-05-14
release: 1.28.7
aliases:
    - /news/announcing-1.28.7
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.28.6 and 1.28.7.

{{< relnote >}}

## Changes

- **Added** support to Gateway API v1.4.1.

- **Added** an `istioctl analyze` warning (IST0175) when `RequestAuthentication` resources exist
but `BLOCKED_CIDRS_IN_JWKS_URIS` is not configured on istiod.
  ([Issue #59523](https://github.com/istio/istio/issues/59523))

- **Added** feature flags `PILOT_HBONE_INITIAL_STREAM_WINDOW_SIZE` and `PILOT_HBONE_INITIAL_CONNECTION_WINDOW_SIZE`.
They can configure the initial stream and connection window sizes for HBONE connections to upstream clusters
(generated for waypoints and east-west gateways). These may be used to reduce unwanted buffering.
  ([Issue #59961](https://github.com/istio/istio/issues/59961))

- **Fixed** an issue where waypoints failed to add the TLS inspector
listener filter when only TLS ports existed, causing SNI-based routing
to fail for wildcard ServiceEntry with `resolution: DYNAMIC_DNS`.
  ([Issue #59024](https://github.com/istio/istio/issues/59024))

- **Fixed** an issue where Istiod could issue leaf certificates with a `NotAfter` time beyond
the signing certificate's expiration.
  ([Issue #59768](https://github.com/istio/istio/issues/59768))

- **Fixed** kubelet health probe failures for ambient mesh pods on AWS EKS when using
Security Groups for Pods (branch ENI). istio-cni now detects branch ENI pods and
adds IP rules to route probe traffic via the veth pair instead of VPC fabric.
Gated behind the feature flag `AMBIENT_ENABLE_AWS_BRANCH_ENI_PROBE` (enabled by default).

- **Fixed** XDS debug endpoints (`istio.io/debug/syncz` and `istio.io/debug/config_dump`) served by `StatusGen` to enforce
same-namespace authorization for non-system callers. Previously an authenticated workload from any namespace could
enumerate proxies and retrieve configuration dumps for workloads in other namespaces.

**Credit**: This vulnerability was discovered and reported by [1seal](https://github.com/1seal).

## Security update

- Fixed an authorization bypass in `AuthorizationPolicy` where regex metacharacters in certain identity fields were embedded in the generated Envoy `SafeRegex` without escaping. As a result, legal Kubernetes names containing characters like `.` or `[` could be treated as regex wildcards, admitting identities beyond the policy author's intent. This issue affected `source.principals` (specifically suffix matches starting with `*`) and `source.namespaces`.
  ([Issue #59992](https://github.com/istio/istio/issues/59992))

**Credit**: This vulnerability was discovered and reported by [Alex](https://github.com/Alex0Young).

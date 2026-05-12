---
title: Announcing Istio 1.29.3
linktitle: 1.29.3
subtitle: Patch Release
description: Istio 1.29.3 patch release.
publishdate: 2026-05-13
release: 1.29.3
aliases:
    - /news/announcing-1.29.3
---

{{< warning >}}
This is an automatically generated rough draft of the release notes and has not yet been reviewed.
{{< /warning >}}

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.29.2 and 1.29.3.

{{< relnote >}}

## Changes

- **Added** support to Gateway API v1.4.1.

- **Added** an `istioctl analyze` warning (IST0175) when `RequestAuthentication` resources exist
but `BLOCKED_CIDRS_IN_JWKS_URIS` is not configured on istiod.
  ([Issue #59523](https://github.com/istio/istio/issues/59523))

- **Added** Initial HTTP/2 stream and connection window sizes for HBONE CONNECT upstream clusters (generated for
waypoints and east-west gateways) can be configured using feature flags
`PILOT_HBONE_INITIAL_STREAM_WINDOW_SIZE` and `PILOT_HBONE_INITIAL_CONNECTION_WINDOW_SIZE`. These may be used to
reduce unwanted buffering.
  ([Issue #59961](https://github.com/istio/istio/issues/59961))

- **Fixed** an issue where Istiod could issue leaf certificates with a `NotAfter` time beyond
the signing certificate's expiration.
  ([Issue #59768](https://github.com/istio/istio/issues/59768))

- **Fixed** a deadlock in the multicluster secret controller that could occur during remote cluster updates.  ([Issue #59875](https://github.com/istio/istio/issues/59875))

- - **Fixed** pilot-agent missing certificate reloads on second and subsequent Kubernetes secret rotations for file-mounted certs.
  ([Issue #59912](https://github.com/istio/istio/issues/59912))

- **Fixed** an authorization bypass in `AuthorizationPolicy` matching for SPIFFE identities and namespaces. Regex metacharacters in fields like `source.principals` (suffix matching) and `source.namespaces` were not properly escaped in the generated Envoy configuration, potentially allowing unintended identities to match policy rules.
  ([Issue #59992](https://github.com/istio/istio/issues/59992))

- **Fixed** kubelet health probe failures for ambient mesh pods on AWS EKS when using
Security Groups for Pods (branch ENI). istio-cni now detects branch ENI pods and
adds ip rules to route probe traffic via the veth pair instead of VPC fabric.
Gated behind `AMBIENT_ENABLE_AWS_BRANCH_ENI_PROBE` (enabled by default).

- **Fixed** an issue where `istioctl ztunnel-config service` JSON and YAML output did not include the `canonical` field from the ztunnel config dump.
  ([Issue #59962](https://github.com/istio/istio/issues/59962))

- **Fixed** XDS debug endpoints (`istio.io/debug/syncz`, `istio.io/debug/config_dump`) served by `StatusGen` to enforce
same-namespace authorization for non-system callers. Previously an authenticated workload from any namespace could
enumerate proxies and retrieve config dumps for workloads in other namespaces.

**Credit**: This vulnerability was discovered and reported by [1seal](https://github.com/1seal).

## Security update

- Fixed an authorization bypass in `AuthorizationPolicy` where regex metacharacters in certain identity fields were embedded in the generated Envoy `SafeRegex` without escaping. As a result, legal Kubernetes names containing characters like `.` or `[` could be treated as regex wildcards, admitting identities beyond the policy author's intent. This issue affected `source.principals` (specifically suffix matches starting with `*`) and `source.namespaces`.

**Credit**: This vulnerability was discovered and reported by [Alex](https://github.com/Alex0Young).

---
title: Announcing Istio 1.22.1
linktitle: 1.22.1
subtitle: Patch Release
description: Istio 1.22.1 patch release.
publishdate: 2024-06-04
release: 1.22.1
---

This release implements the security updates described in our 4th of June post, [`ISTIO-SECURITY-2024-004`](/news/security/istio-security-2024-004) along with bug fixes to improve robustness.

This release note describes what’s different between Istio 1.22.0 and 1.22.1.

{{< relnote >}}

## Changes

- **Added** a new, optional experimental admission policy that only allows stable features/fields to be used in Istio APIs when using a remote Istiod cluster.
  ([Issue #173](https://github.com/istio/enhancements/issues/173))

- **Fixed** adding of pod IPs to the host's `ipset` to explicitly fail instead of silently overwriting.

- **Fixed** an issue causing `outboundstatname` in MeshConfig to not be honored for subset clusters.

- **Fixed** custom injection of the `istio-proxy` container not working properly when `SecurityContext.RunAs` fields were set.

- **Fixed** returning 503 errors by auto-passthrough gateways created after enabling mTLS.

- **Fixed** `serviceRegistry` orders influence the proxy labels, so we put the Kubernetes registry in front.
  ([Issue #50968](https://github.com/istio/istio/issues/50968))

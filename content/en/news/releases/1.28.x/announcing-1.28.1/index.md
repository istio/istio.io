---
title: Announcing Istio 1.28.1
linktitle: 1.28.1
subtitle: Patch Release
description: Istio 1.28.1 patch release.
publishdate: 2025-12-03
release: 1.28.1
aliases:
    - /news/announcing-1.28.1
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.28.0 and 1.28.1.

This release implements the security updates described in our 3rd of December post, [`ISTIO-SECURITY-2025-003`](/news/security/istio-security-2025-003).

{{< relnote >}}

## Changes

- **Added** support for multiple `targetPorts` in an `InferencePool`. The possibility to have >1 `targetPort` was added as part of GIE v1.1.0.
  ([Issue #57638](https://github.com/istio/istio/issues/57638))

- **Fixed** status conflicts on Route resources when multiple Istio revisions are installed.
  ([Issue #57734](https://github.com/istio/istio/issues/57734))

- **Fixed** `ServiceEntry` resources with overlapping hostnames within the same namespace causing unpredictable
behavior in ambient mode.
  ([Issue #57291](https://github.com/istio/istio/issues/57291))

- **Fixed** a failure in `istio-init` when using native nftables with TPROXY mode and had an empty `traffic.sidecar.istio.io/includeInboundPorts` annotation.
  ([Issue #58135](https://github.com/istio/istio/issues/58135))

- **Fixed** an issue where EDS generation code did not consider service scope and, as a result, remote cluster endpoints that should not be accessible were included in waypoint configuration.
  ([Issue #58139](https://github.com/istio/istio/issues/58139))

- **Fixed** an issue where, due to incorrect EDS caching in pilot, ambient E/W gateway or waypoints would be configured with unusable EDS endpoints.
  ([Issue #58141](https://github.com/istio/istio/issues/58141))

- **Fixed** an issue where Envoy Secret resources could get stuck in `WARMING` state when the same Kubernetes Secret is referenced from Istio Gateway objects using both `secret-name` and `namespace/secret-name` formats.
  ([Issue #58146](https://github.com/istio/istio/issues/58146))

- **Fixed** an issue where IPv6 nftables rules were programmed when IPv6 was explicitly disabled in ambient mode.
  ([Issue #58249](https://github.com/istio/istio/issues/58249))

- **Fixed** DNS name table creation for headless services where pods entries did not account for pods having multiple IPs.  ([Issue #58397](https://github.com/istio/istio/issues/58397))

- **Fixed** an issue causing ambient multi-network connections to fail when using a custom trust domain.
  ([Issue #58427](https://github.com/istio/istio/issues/58427))

- **Fixed** an issue where HTTPS servers processed first prevented HTTP servers from creating routes on the same port with different bind addresses.  ([Issue #57706](https://github.com/istio/istio/issues/57706))

- **Fixed** a bug causing the experimental `XListenerSet` resources to not be able to access TLS Secrets.

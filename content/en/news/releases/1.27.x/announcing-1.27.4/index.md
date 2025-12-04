---
title: Announcing Istio 1.27.4
linktitle: 1.27.4
subtitle: Patch Release
description: Istio 1.27.4 patch release.
publishdate: 2025-12-03
release: 1.27.4
aliases:
    - /news/announcing-1.27.4
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.27.3 and 1.27.4.

This release implements the security updates described in our 3rd of December post, [`ISTIO-SECURITY-2025-003`](/news/security/istio-security-2025-003).

{{< relnote >}}

## Changes

- **Fixed** status conflicts on Route resources when multiple istio revisions are installed.
  ([Issue #57734](https://github.com/istio/istio/issues/57734))

- **Fixed** an issue with waypoints where an `EnvoyFilter` with `targetRef` kind `GatewayClass` and group `gateway.networking.k8s.io` in the root namespace would not work.

- **Fixed** a failure in `istio-init` when using native nftables with TPROXY mode and had an empty `traffic.sidecar.istio.io/includeInboundPorts` annotation.
  ([Issue #58135](https://github.com/istio/istio/issues/58135))

- **Fixed** an issue where Envoy Secret resources could get stuck in `WARMING` state when the same Kubernetes Secret is referenced from Istio Gateway objects using both `secret-name` and `namespace/secret-name` formats.
  ([Issue #58146](https://github.com/istio/istio/issues/58146))

- **Fixed** DNS name table creation for headless services where pods entries did not account for pods having multiple IPs.  ([Issue #58397](https://github.com/istio/istio/issues/58397))

- **Fixed** an issue where HTTPS servers processed first prevented HTTP servers from creating routes on the same port with different bind addresses.  ([Issue #57706](https://github.com/istio/istio/issues/57706))

- **Fixed** a bug causing the experimental `XListenerSet` resources to not be able to access TLS Secrets.

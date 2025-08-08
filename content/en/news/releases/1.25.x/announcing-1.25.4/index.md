---
title: Announcing Istio 1.25.4
linktitle: 1.25.4
subtitle: Patch Release
description: Istio 1.25.4 patch release.
publishdate: 2025-08-08
release: 1.25.4
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.25.3 and Istio 1.25.4.

{{< relnote >}}

## Changes

- **Fixed** an issue where Istio upgrade from 1.24 to 1.25 caused service disruption due to preexisting iptables rules.
    The iptables binary detection logic has been improved to verify a degree of baseline kernel support exists, and prefer `nft` in a `tie` situation.

- **Fixed** an issue causing false positives with `istioctl analyze` raising IST0134 even when `PILOT_ENABLE_IP_AUTOALLOCATE` was set to `true`.
  ([Issue #56083](https://github.com/istio/istio/issues/56083))

- **Fixed** a panic in `istioctl manifest translate` when the IstioOperator config contained multiple gateways.
  ([Issue #56223](https://github.com/istio/istio/issues/56223))

- **Fixed** ambient index to filter configs by revision.
  ([Issue #56477](https://github.com/istio/istio/issues/56477))

- **Fixed** incorrect UID and GID assignment for `istio-proxy` and `istio-validation` containers on OpenShift when TPROXY mode was enabled.

- **Fixed** logic to properly ignore the `topology.istio.io/network` label on the system namespace when `discoverySelectors` are in use.
  ([Issue #56687](https://github.com/istio/istio/issues/56687))

- **Fixed** an issue where access logs were not updated when the referenced service was created later than the Telemetry resource.  ([Issue #56825](https://github.com/istio/istio/issues/56825))

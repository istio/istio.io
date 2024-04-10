---
title: Announcing Istio 1.20.5
linktitle: 1.20.5
subtitle: Patch Release
description: Istio 1.20.5 patch release.
publishdate: 2024-04-08
release: 1.20.5
---

This release implements the security updates described in our 8th of April post, [`ISTIO-SECURITY-2024-002`](/news/security/istio-security-2024-002) along with bug fixes to improve robustness.

This release note describes what’s different between Istio 1.20.4 and 1.20.5.

{{< relnote >}}

## Changes

- **Fixed** a bug where `VirtualService`s containing duplicate hosts with different cases would cause routes to be rejected by Envoy.
  ([Issue #49638](https://github.com/istio/istio/issues/49638))

- **Fixed** an issue where commands relying on Envoy config dump would not work due to the presence of ECDS config.

- **Fixed** an issue where telemetry `EnvoyFilter` resources were not correctly pruned during the installation process.
  ([Issue #48126](https://github.com/istio/istio/issues/48126))

- **Fixed** an issue where pilot CPU consumption was abnormally high when the in-cluster analysis was enabled.
  ([Issue #49340](https://github.com/istio/istio/issues/49340))

- **Fixed** an issue where updating a `ServiceEntry`'s `TargetPort` would not trigger an xDS push.
  ([Issue #49878](https://github.com/istio/istio/issues/49878))

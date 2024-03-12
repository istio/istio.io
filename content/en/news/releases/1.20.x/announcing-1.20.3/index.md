---
title: Announcing Istio 1.20.3
linktitle: 1.20.3
subtitle: Patch Release
description: Istio 1.20.3 patch release.
publishdate: 2024-02-09
release: 1.20.3
---

This release implements the security updates described in our February 8th post, [`ISTIO-SECURITY-2024-001`](/news/security/istio-security-2024-001) along with bug fixes to improve robustness.

This release note describes what’s different between Istio 1.20.2 and 1.20.3.

{{< relnote >}}

## Changes

- **Improved** graceful termination abort logic when the Envoy process terminates early.  ([Issue #36686](https://github.com/istio/istio/issues/36686))

- **Fixed** an issue where updating a service's `TargetPort` does not trigger an xDS push.  ([Issue #48580](https://github.com/istio/istio/issues/48580))

- **Fixed** an issue where in-cluster analysis was unnecessarily performed when there's no configuration change.
  ([Issue #48665](https://github.com/istio/istio/issues/48665))

- **Fixed** an issue where the webhook generated with `istioctl tag set` is unexpectedly removed by the installer.
  ([Issue #47423](https://github.com/istio/istio/issues/47423))

- **Fixed** a bug that results in the incorrect generation of configurations for pods without associated services, which includes all services within the same namespace. This can occasionally lead to conflicting inbound listeners error.

- **Fixed** a bug that made `PeerAuthentication` too restrictive in ambient mode.

- **Fixed** an issue causing Istio CNI to stop functioning on minimal/locked down nodes (such as no `sh` binary).
The new logic runs with no external dependencies, and will attempt to continue if errors are encountered (which could be caused by things like SELinux rules).
In particular, this fixes running Istio on Bottlerocket nodes.
  ([Issue #48746](https://github.com/istio/istio/issues/48746))

---
title: Announcing Istio 1.7.1
linktitle: 1.7.1
subtitle: Patch Release
description: Istio 1.7.1 patch release.
publishdate: 2020-09-10
release: 1.7.1
aliases:
    - /news/announcing-1.7.1
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.7.0 and Istio 1.7.1

{{< relnote >}}

## Changes

- **Added** Envoy [ext `authz` and gRPC access log API support](https://github.com/istio/istio/wiki/Enabling-Envoy-Authorization-Service-and-gRPC-Access-Log-Service-With-Mixer) in Mixer,
which makes Mixer based configuration and out of process adapter still work after upgrading to future versions of Istio.
  ([Issue #23580](https://github.com/istio/istio/issues/23580))

- **Fixed** the `istioctl x authz check` command to work properly with the v1beta1 AuthorizationPolicy.
  ([PR #26625](https://github.com/istio/istio/pull/26625))

- **Fixed** unreachable endpoints for non-injected workloads across networks by removing them.
  ([Issue #26517](https://github.com/istio/istio/issues/26517))

- **Fixed** enabling hold application until proxy starts feature flag breaking rewriting application probe logic.
  ([Issue #26873](https://github.com/istio/istio/issues/26873))

- **Fixed** deleting the remote-secret for multicluster installation removes remote endpoints.
  ([Issue #27187](https://github.com/istio/istio/issues/27187))

- **Fixed** missing endpoints when Service is populated later than Endpoints.

- **Fixed** an issue causing headless Service updates to be missed ([Issue #26617](https://github.com/istio/istio/issues/26617)).
  ([Issue #26617](https://github.com/istio/istio/issues/26617))

- **Fixed** an issue with Kiali RBAC permissions which prevented its deployment from working properly.
  ([Issue #27109](https://github.com/istio/istio/issues/27109))

- **Fixed** an issue where `remove-from-mesh` did not remove the init containers when using Istio CNI
  ([Issue #26938](https://github.com/istio/istio/issues/26938))

- **Fixed** Kiali to use anonymous authentication strategy since newer versions have removed the login authentication strategy.

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

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio x.y.(z-1) and Istio x.y.z

{{< relnote >}}

# Changes



- **Added** Envoy [ext authz and gRPC access log API support](https://github.com/istio/istio/wiki/Enabling-Envoy-Authorization-Service-and-gRPC-Access-Log-Service-With-Mixer) in Mixer,
which makes Mixer based configuration and out of process adapter still work after upgrading to future version of Istio. 
  ([Issue #23580](https://github.com/istio/istio/issues/23580))



- **Fixed** Remove unreachable endpoints for non-injected workloads across networks.
  ([Issue #26517](https://github.com/istio/istio/issues/26517))

- **Fixed** HoldApplicationUntilProxyStarts breaks rewriteAppProbers.
  ([Issue #26873](https://github.com/istio/istio/issues/26873))

- **Fixed** deleting the remote-secret for multicluster installation removes remote endpoints.
  

- **Fixed** endpoint missed from eds when kubernetes service populated later than endpoints.
  

- **Fixed** headless services endpoints update will not trigger any xds pushes for sidecar proxies
  ([Issue #26617](https://github.com/istio/istio/issues/26617))

- **Fixed** an issue with Kiali RBAC permissions which prevented its deployment from working properly.
  ([Issue #27109](https://github.com/istio/istio/issues/27109))

- **Fixed** remove-from-mesh does not remove the init containers when using Istio CNI
  ([Issue #26938](https://github.com/istio/istio/issues/26938))

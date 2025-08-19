---
title: Announcing Istio 1.8.2
linktitle: 1.8.2
subtitle: Patch Release
description: Istio 1.8.2 patch release.
publishdate: 2021-01-14
release: 1.8.2
aliases:
    - /news/announcing-1.8.2
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.8.1 and Istio 1.8.2

{{< relnote >}}

## Changes

- **Improved** `WorkloadEntry` auto-registration stability.
  ([PR #29876](https://github.com/istio/istio/pull/29876))

- **Fixed** the CA's certificate signature algorithm to be the default algorithm corresponding to the CA's signing key type.
  ([Issue #27238](https://github.com/istio/istio/issues/27238))

- **Fixed** Newer control plane installations were removing permissions for `rbac.istio.io` from `istiod`, causing
older control planes relying on that CRD group to hang on restart.
  ([Issue #29364](https://github.com/istio/istio/issues/29364))

- **Fixed** empty service ports for customized gateway.
  ([Issue #29608](https://github.com/istio/istio/issues/29608))

- **Fixed** an issue causing usage of deprecated filter names in `EnvoyFilter` to overwrite other `EnvoyFilter`s.
  ([Issue #29858](https://github.com/istio/istio/issues/29858))([Issue #29909](https://github.com/istio/istio/issues/29909))

- **Fixed** an issue causing `EnvoyFilter`s that match filter chains to fail to properly apply.
   ([PR #29486](https://github.com/istio/istio/pull/29486))

- **Fixed** an issue causing a Secret named `<secret>-cacert` to have lower precedence than a Secret named `<secret>` for Gateway Mutual TLS. This behavior was accidentally inverted in Istio 1.8; this change restores the behavior to match Istio 1.7 and earlier.
  ([Issue #29856](https://github.com/istio/istio/issues/29856))

- **Fixed** an issue causing only internal ALPN values to be set during external TLS origination.
  ([Issue #24619](https://github.com/istio/istio/issues/24619))

- **Fixed** an issue causing client side application TLS requests sent to a PERMISSIVE mode enabled server to fail.
  ([Issue #29538](https://github.com/istio/istio/issues/29538))

- **Fixed** an issue causing the `targetPort` option to not take affect for `WorkloadEntry`s with multiple ports.
  ([PR #29887](https://github.com/istio/istio/pull/29887))

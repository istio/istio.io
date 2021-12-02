---
title: Announcing Istio 1.11.5
linktitle: 1.11.5
subtitle: Patch Release
description: Istio 1.11.5 patch release.
publishdate: 2021-12-02
release: 1.11.5
aliases:
    - /news/announcing-1.11.5
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.11.4 and Istio 1.11.5

{{< relnote >}}

## Changes

- **Fixed** istiod deployment respect `values.pilot.nodeSelector`.
  ([Issue #36110](https://github.com/istio/istio/issues/36110))

- **Fixed** the in-cluster operator can't prune resources when the Istio control plane have active proxies connected.
  ([Issue #35657](https://github.com/istio/istio/issues/35657))

- **Fixed** the release tar URL by adding the patch version.

- **Fixed** `LbEndpointValidationError.LoadBalancingWeight: value must be greater than or equal to 1`  from Envoy when
multi-network gateways are configured via `MeshNetworks`.

- **Fixed** workload name metric labels are not correctly populated for `CronJob` at k8s 1.21+.
  ([Issue #35563](https://github.com/istio/istio/issues/35563))

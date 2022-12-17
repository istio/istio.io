---
title: Announcing Istio 1.15.4
linktitle: 1.15.4
subtitle: Patch Release
description: Istio 1.15.4 patch release.
publishdate: 2022-12-12
release: 1.15.4
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.15.3 and Istio 1.15.4.

This release includes security fixes in Go 1.19.4 (released 2022-12-06) for the `os` and `net/http` packages.

{{< relnote >}}

## Changes

- **Improved** when Wasm module downloading fails and `fail_open` is true, a RBAC filter allowing all the traffic is passed to Envoy instead of the original Wasm filter. Previously, the given Wasm filter itself was passed to Envoy in this case, but it may cause errors because some fields of Wasm configuration are optional in Istio, but not in Envoy.

- **Fixed** an issue when deleting a custom Gateway using an Istio Operator resource, other gateways are restarted.
  ([Issue #40577](https://github.com/istio/istio/issues/40577))

- **Fixed** an issue where Istio Operator could not create the CNI properly when `cni.resourceQuotas` is enabled.
  ([Issue #41159](https://github.com/istio/istio/issues/41159))

- **Fixed** an issue where `istiod`, when started with `PILOT_ENABLE_STATUS=true`, lacked permissions to clean up the distribution report ConfigMap.

- **Fixed** an issue where `pilotExists` always returned `false`.  ([Issue #41631](https://github.com/istio/istio/issues/41631))

- **Fixed** an issue where gateway pods were not respecting the `global.imagePullPolicy` specified in the Helm values.

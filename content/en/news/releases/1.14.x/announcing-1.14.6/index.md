---
title: Announcing Istio 1.14.6
linktitle: 1.14.6
subtitle: Patch Release
description: Istio 1.14.6 patch release.
publishdate: 2022-12-12
release: 1.14.6
---

This release contains bug fixes to improve robustness. This release note describes what is different between Istio 1.14.5 and Istio 1.14.6.

FYI, this release includes security fixes in Go 1.18.9 (released on 2022-12-06).

{{< relnote >}}

## Changes

- **Fixed** an issue when deleting a custom gateway using an Istio Operator custom resource, other gateways are restarted.
  ([Issue #40577](https://github.com/istio/istio/issues/40577))

- **Fixed** an issue with missing `service_name` in Telemetry API when configuring Datadog tracing provider.
  ([Issue #38573](https://github.com/istio/istio/issues/38573))

- **Fixed** an issue where a wrong schema configuration caused the Istio Operator to go into an error loop.
  ([Issue #40876](https://github.com/istio/istio/issues/40876))

- **Fixed** an issue where gateway pods did not respect the `global.imagePullPolicy` specified in the Helm values.

- **Added** warning validation messages when a DestinationRule specifies failover policies but does not provide an `OutlierDetection` policy.
  Previously, istiod silently ignored the failover settings.

- **Improved** when Wasm module downloading fails and `fail_open` is true, a RBAC filter allows all traffic to pass to `Envoy` instead of the original Wasm filter.
  Previously, the given Wasm filter itself was passed to `Envoy` in this case, but it may cause errors because some fields of Wasm configuration are optional in Istio, but not in `Envoy`.

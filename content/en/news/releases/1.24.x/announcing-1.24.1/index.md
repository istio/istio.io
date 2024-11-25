---
title: Announcing Istio 1.24.1
linktitle: 1.24.1
subtitle: Patch Release
description: Istio 1.24.1 patch release.
publishdate: 2024-11-25
release: 1.24.1
---

This release note describes what is different between Istio 1.24.0 and 1.24.1.

{{< relnote >}}

## Changes

- **Added** unconfined AppArmor annotation to the `istio-cni-node` `DaemonSet` to avoid conflicts with
  AppArmor profiles which block certain privileged pod capabilities. Previously, AppArmor
  (when enabled) was bypassed for the `istio-cni-node` `DaemonSet` since privileged was set to true
  in the `SecurityContext`. This change ensures that the AppArmor profile is set to unconfined
  for the `istio-cni-node` `DaemonSet`.

- **Added** `dnsPolicy` of `ClusterFirstWithHostNet` to `istio-cni` when it runs with `hostNetwork=true` (i.e. ambient mode).

- **Fixed** an issue where `istioctl install` was not working as expected on Windows.

- **Fixed** an issue where merging `Duration` with an `Envoyfilter` can lead to all listeners associated attributes unexpectedly became modified
  because all of the listeners shared the same pointer typed `listener_filters_timeout`.

- **Fixed** an issue where `istioctl install` deadlocks if multiple ingress gateways are specified in the IstioOperator file
  ([Issue #53875](https://github.com/istio/istio/issues/53875))

- **Fixed** an issue where errors were being raised during cleanup of iptables rules that are conditional on the iptables configuration.

- **Fixed** an issue when upgrading waypoint proxies from Istio 1.23.x to Istio 1.24.x.
  ([Issue #53883](https://github.com/istio/istio/issues/53883))

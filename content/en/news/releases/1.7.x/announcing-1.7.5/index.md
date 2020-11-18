---
title: Announcing Istio 1.7.5
linktitle: 1.7.5
subtitle: Patch Release
description: Istio 1.7.5 patch release.
publishdate: 2020-11-19
release: 1.7.5
aliases:
- /news/announcing-1.7.5
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.7.4 and Istio 1.7.5

{{< relnote >}}

## Changes

- **Fixed** pilot agent app probe connection leak. ([Issue #27726](https://github.com/istio/istio/issues/27726))

- **Fixed** how `install-cni` applies `istio-cni` plugin configuration, `Install-cni` will now remove existing `istio-cni` plugins from the CNI config before inserting `istio-cni` plugin configuration (new behavior) rather than just append a new configuration to the existing list (former behavior). ([Issue #27771](https://github.com/istio/istio/issues/27771))

- **Fixed** when a node has multiple IP addresses (e.g., a VM in the mesh expansion scenario), Istio Proxy will now bind inbound listeners to the first applicable address in the list (new behavior) rather than to the last one (former behavior). ([Issue #28269](https://github.com/istio/istio/issues/28269))

- **Fixed** when proxy is configured with `FILE_MOUNTED_CERTS`, gateway secret fetcher is not run.

- **Fixed** multicluster `EnvoyFilter` to have valid configuration following the underlying changes in Envoy’s API. ([Issue #27909](https://github.com/istio/istio/issues/27909))

- **Fixed** an issue causing a short spike in errors during in place upgrades from Istio 1.6 to Istio 1.7. As a result of this fix, users who already have Istio 1.7 deployed but still have proxies left on version 1.6 will see a similar spike during this upgrade. It is highly recommended you either migrate all existing proxies to version 1.7 prior to this release. Alternatively, to retain the previous behavior, you may set the `PILOT_ENABLE_TLS_XDS_DYNAMIC_TYPES`=false environment variable in Istiod. ([Issue #28120](https://github.com/istio/istio/issues/28120))


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

- **Fixed** how `install-cni` applies `istio-cni` plugin configuration. Previously, new configurations would be appended to the list. This has been changed to remove existing `istio-cni` plugins from the CNI config before inserting new plugins. ([Issue #27771](https://github.com/istio/istio/issues/27771))

- **Fixed** when a node has multiple IP addresses (e.g., a VM in the mesh expansion scenario). Istio Proxy will now bind inbound listeners to the first applicable address in the list rather than to the last one. ([Issue #28269](https://github.com/istio/istio/issues/28269))

- **Fixed** Istio to not run gateway secret fetcher when proxy is configured with `FILE_MOUNTED_CERTS`.

- **Fixed** multicluster `EnvoyFilter` to have valid configuration following the underlying changes in Envoy’s API. ([Issue #27909](https://github.com/istio/istio/issues/27909))

- **Fixed** an issue causing a short spike in errors during in place upgrades from Istio 1.6 to 1.7. Previously, the TLS version would be upgraded automatically from `TLSv2` to `TLSv3`. This caused a spike in errors if there was a mix of Istio 1.6 and Istio 1.7 proxies running. The `PILOT_ENABLE_TLS_XDS_DYNAMIC_TYPES`=false environment variable was added to disable automatic TLS version updates. This is enabled by default but should be disabled for upgrades from Istio 1.6 to Istio 1.7. ([Issue #28120](https://github.com/istio/istio/issues/28120))

- **Fixed** missing listeners on a VM when the VM sidecar is connected to `istiod` but a `WorkloadEntry` is registered later. ([Issue #28743](https://github.com/istio/istio/issues/28743))

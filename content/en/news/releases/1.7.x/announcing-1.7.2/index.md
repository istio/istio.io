---
title: Announcing Istio 1.7.2
linktitle: 1.7.2
subtitle: Patch Release
description: Istio 1.7.2 patch release.
publishdate: 2020-09-18
release: 1.7.2
aliases:
    - /news/announcing-1.7.2
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.7.1 and Istio 1.7.2

{{< relnote >}}

## Changes

- **Fixed** locality load balancer settings being applied to inbound clusters unnecessarily. ([Issue #27293](https://github.com/istio/istio/issues/27293))

- **Fixed** unbounded cardinality of Istio metrics for `CronJob` job workloads. ([Issue #24058](https://github.com/istio/istio/issues/24058))

- **Fixed** setting the `ISTIO_META_REQUESTED_NETWORK_VIEW` environment variable for a proxy will filter out endpoints that aren’t part of the comma-separated list of networks. This should be set to the local-network on the ingress-gateway used for cross-network traffic to prevent odd load balancing behavior. ([Issue #26293](https://github.com/istio/istio/issues/26293))

- **Fixed** issues with `WorkloadEntry` when the Service or `WorkloadEntry` is updated after creation. ([Issue #27183](https://github.com/istio/istio/issues/27183)),([Issue #27151](https://github.com/istio/istio/issues/27151)),([Issue #27185](https://github.com/istio/istio/issues/27185))

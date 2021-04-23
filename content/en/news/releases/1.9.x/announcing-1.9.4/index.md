---
title: Announcing Istio 1.9.4
linktitle: 1.9.4
subtitle: Patch Release
description: Istio 1.9.4 patch release.
publishdate: 2020-04-27
release: 1.9.4
aliases:
    - /news/announcing-1.9.4
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.9.3 and Istio 1.9.4

{{< relnote >}}

## Changes

- **Fixed** an issue where the Istio operator prunes the resource that doesn't belong to specific Istio operator CR. ([Issue #30833](https://github.com/istio/istio/issues/30833))

- **Fixed** an issue ensuring lease duration is always greater than the user configured `RENEW_DEADLINE` for Istio operator manager. ([Issue #27509](https://github.com/istio/istio/issues/27509))

- **Fixed** an issue where a certificate provisioned by sidecar proxy cannot be used by Prometheus. ([Issue #29919](https://github.com/istio/istio/issues/29919))

- **Fixed** an issue that creates an IOP under `istio-system` when installing Istio in another namespace. ([Issue #31517](https://github.com/istio/istio/issues/31517))

- **Fixed** an issue when using `PeerAuthentication` to turn off mTLS while using multi-network, non-mTLS endpoints will be removed from the cross-network load-balancing endpoints to prevent 500 errors. ([Issue #28798](https://github.com/istio/istio/issues/28798))

- **Improved** the `istioctl x workload` command to configure VMs to disable inbound `iptables` capture for admin ports, matching the behavior of Kubernetes Pods. ([Issue #29412](https://github.com/istio/istio/issues/29412))

---
title: Announcing Istio 1.16.5
linktitle: 1.16.5
subtitle: Patch Release
description: Istio 1.16.5 patch release.
publishdate: 2023-05-23
release: 1.16.5
---

This release note describes what’s different between Istio 1.16.4 and 1.16.5.

{{< relnote >}}

## Changes

- **Updated** VirtualService validation to fail on empty prefix header matcher.
  ([Issue #44424](https://github.com/istio/istio/issues/44424))

- **Fixed** the `dns_upstream_failures_total` metric that was mistakenly deleted in the previous release.
  ([Issue #44151](https://github.com/istio/istio/issues/44151))

- **Fixed** a bug where services are missing in gateways if `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG` is enabled.
  ([Issue #44439](https://github.com/istio/istio/issues/44439))

- **Fixed** an issue with forward compatibility with Istio 1.18+ [Kubernetes Gateway Automated Deployment](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment).
  To have a seamless upgrade to 1.18+, users of this feature should first adopt this patch release.
  ([Issue #44164](https://github.com/istio/istio/issues/44164))

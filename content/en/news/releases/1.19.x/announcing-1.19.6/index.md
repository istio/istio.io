---
title: Announcing Istio 1.19.6
linktitle: 1.19.6
subtitle: Patch Release
description: Istio 1.19.6 patch release.
publishdate: 2024-01-05
release: 1.19.6
---

This release note describes what’s different between Istio 1.19.5 and 1.19.6.

{{< relnote >}}

## Changes

- **Fixed** a bug where overlapping wildcard hosts in a `VirtualService` produces incorrect routing configurations
  when wildcard services were selected (e.g. in `ServiceEntry`).
  ([Issue #45415](https://github.com/istio/istio/issues/45415))

- **Fixed** an issue where the Istio injection webhook may be modified in dry-run mode.
  ([Issue #48241](https://github.com/istio/istio/issues/48241))

- **Fixed** an issue where the QUIC listeners were not correctly created when dual-stack is enabled.
  ([Issue #48336](https://github.com/istio/istio/issues/48336))

- **Fixed** an issue where `istioctl proxy-config ecds` didn't display all `EcdsConfigDump`.

- **Fixed** an issue where new endpoints may not be sent to proxies.
  ([Issue #48373](https://github.com/istio/istio/issues/48373))

- **Fixed** an issue where installing with Stackdriver and using custom configurations would prevent Stackdriver from being
  enabled.

- **Fixed** an issue where long-lived connections, TCP bytes and gRPC, could result in a proxy memory leak.

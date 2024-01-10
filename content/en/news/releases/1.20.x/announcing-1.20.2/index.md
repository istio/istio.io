---
title: Announcing Istio 1.20.2
linktitle: 1.20.2
subtitle: Patch Release
description: Istio 1.20.2 patch release.
publishdate: 2024-01-09
release: 1.20.2
---

This release note describes what’s different between Istio 1.20.1 and 1.20.2.

{{< relnote >}}

## Changes

- **Added** configurable scaling behavior for Gateway `HorizontalPodAutoscaler` in the helm chart.
  ([usage]( https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior))

- **Fixed** a bug where overlapping wildcard hosts in a `VirtualService` produces incorrect routing configurations
  when wildcard services were selected (e.g. in `ServiceEntry`).
  ([Issue #45415](https://github.com/istio/istio/issues/45415))

- **Fixed** an issue where Istio was performing additional XDS pushes for `StatefulSets` and headless `Service`
  endpoints while scaling.
  ([Issue #48207](https://github.com/istio/istio/issues/48207))

- **Fixed** an issue where the Istio injection webhook may be modified in dry-run mode.
  ([Issue #48241](https://github.com/istio/istio/issues/48241))

- **Fixed** an issue if `DestinationRule`'s `exportTo` includes workload's current namespace (not '.'), other namespaces
  are ignored from `exportTo`.
  ([Issue #48349](https://github.com/istio/istio/issues/48349))

- **Fixed** an issue where the QUIC listeners were not correctly created when dual-stack is enabled.
  ([Issue #48336](https://github.com/istio/istio/issues/48336))

- **Fixed** an issue where `istioctl proxy-config ecds` didn't display all `EcdsConfigDump`.

- **Fixed** an issue where new endpoints may not be sent to proxies.
  ([Issue #48373](https://github.com/istio/istio/issues/48373))

- **Fixed** an issue where installing with Stackdriver and using custom configurations would prevent Stackdriver from
  being enabled.

- **Fixed** an issue where long-lived connections, TCP bytes and gRPC, could result in a proxy memory leak.

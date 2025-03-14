---
title: Announcing Istio 1.24.4
linktitle: 1.24.4
subtitle: Patch Release
description: Istio 1.24.3 patch release.
publishdate: 2025-03-17
release: 1.24.4
---


This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.24.3 and Istio 1.24.4.

{{< relnote >}}

## Changes

- **Fixed** an issue where customizing the workload identity SDS socket name  via `WORKLOAD_IDENTITY_SOCKET_FILE` did not work, due to Envoy bootstrap not being updated.
  ([Issue #51979](https://github.com/istio/istio/issues/51979))

- **Fixed** an issue in `istio-cni` where if a pod being enrolled in an ambient mesh has more than one network namespace, we (incorrectly) selected the
  netns belonging to the newest PID, rather than the oldest PID.
  ([Issue #55139](https://github.com/istio/istio/issues/55139))

- **Fixed** an issue where the gateway injection template didn't respect the `kubectl.kubernetes.io/default-logs-container` and `kubectl.kubernetes.io/default-container` annotations.

- **Fixed** a case where some user-specified values in `IstioOperator` were being overwritten with default values.

- **Fixed** an issue causing VirtualService header name validation to reject valid header names.

- **Fixed** validation webhook rejecting an otherwise valid `connectionPool.tcp.IdleTimeout=0s`.
  ([Issue #55409](https://github.com/istio/istio/issues/55409))

- **Fixed** `IstioCertificateService` to ensure `IstioCertificateResponse.CertChain` contains only a single cert per element in the array.
  ([Issue #1061](https://github.com/istio/ztunnel/issues/1061))

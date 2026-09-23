---
title: Announcing Istio 1.23.3
linktitle: 1.23.3
subtitle: Patch Release
description: Istio 1.23.3 patch release.
publishdate: 2024-10-24
release: 1.23.3
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.23.2 and Istio 1.23.3

{{< relnote >}}

## Changes

- **Added** `clusterLocal` host exclusions for multi-cluster.

- **Added** the metrics port in the `DaemonSet` containers spec of the `istio-cni` chart.

- **Added** the metrics port in the `kube-gateway` container spec of the `istio-discovery` chart.

- **Fixed** `kube-virt-interfaces` rules not being removed by `istio-clean-iptables` tool.
  ([Issue #48368](https://github.com/istio/istio/issues/48368))

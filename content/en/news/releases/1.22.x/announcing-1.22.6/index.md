---
title: Announcing Istio 1.22.6
linktitle: 1.22.6
subtitle: Patch Release
description: Istio 1.22.6 patch release.
publishdate: 2024-10-23
release: 1.22.6
---

This release note describes what’s different between Istio 1.22.5 and 1.22.6.

{{< relnote >}}

## Changes

- **Fixed** support for `clusterLocal` host exclusions for multi-cluster.

- **Fixed** `kube-virt-related` rules not being removed by istio-clean-iptables tool.
  ([Issue #48368](https://github.com/istio/istio/issues/48368))

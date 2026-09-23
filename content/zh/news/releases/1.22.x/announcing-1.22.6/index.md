---
title: 发布 Istio 1.22.6
linktitle: 1.22.6
subtitle: 补丁发布
description: Istio 1.22.6 补丁发布。
publishdate: 2024-10-23
release: 1.22.6
---

本发布说明描述了 Istio 1.22.5 和 Istio 1.22.6 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了对多集群的 `clusterLocal` 主机排除的支持。

- **修复** 修复了 istio-clean-iptables 工具无法删除 `kube-virt-related` 规则的问题。
  ([Issue #48368](https://github.com/istio/istio/issues/48368))

---
title: 发布 Istio 1.23.3
linktitle: 1.23.3
subtitle: 补丁发布
description: Istio 1.23.3 补丁发布。
publishdate: 2024-10-24
release: 1.23.3
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.23.2 和 Istio 1.23.3 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **新增** 添加了多集群的 `clusterLocal` 主机排除。

- **新增** 在 `istio-cni` Chart 的 `DaemonSet` 容器规范中添加了指标端口。

- **新增** 在 `istio-discovery` Chart 的 `kube-gateway` 容器规范中添加了指标端口。

- **修复** 修复了 `kube-virt-interfaces` 规则未被 `istio-clean-iptables` 工具删除的问题。
  ([Issue #48368](https://github.com/istio/istio/issues/48368))

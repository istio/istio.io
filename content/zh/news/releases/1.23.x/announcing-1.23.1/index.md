---
title: 发布 Istio 1.23.1
linktitle: 1.23.1
subtitle: 补丁发布
description: Istio 1.23.1 补丁发布。
publishdate: 2024-09-10
release: 1.23.1
---

本发布说明描述了 Istio 1.23.0 和 Istio 1.23.1 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了控制器分配的 IP 不像临时自动分配的 IP 那样尊重每个代理 DNS 捕获的问题。
  ([Issue #52609](https://github.com/istio/istio/issues/52609))

- **修复** 修复了 waypoint 需要启用 DNS 代理才能使用自动分配 IP 的问题。
  ([Issue #52746](https://github.com/istio/istio/issues/52746))

- **修复** 修复了使用  `pilot-agent istio-clean-iptables`  命令无法删除 `ISTIO_OUTPUT` `iptables` 链的问题。
  ([Issue #52835](https://github.com/istio/istio/issues/52835))

- **修复** 修复了导致 waypoint 中 `DestinationRule` 的任何 `portLevelSettings` 被忽略的问题。
  ([Issue #52532](https://github.com/istio/istio/issues/52532))

- **移除** 删除了将 `kubeconfig` 写入 CNI 网络目录的逻辑。
  ([Issue #52315](https://github.com/istio/istio/issues/52315))

- **移除** 从 `istio-cni` `ConfigMap` 中删除了 `CNI_NET_DIR`，因为它现在不执行任何操作。
  ([Issue #52315](https://github.com/istio/istio/issues/52315))

- **移除** 删除了 Istio 1.23.0 中的一项更改，该更改导致定义了多个地址的 `ServiceEntries` 出现回归。
  注意：恢复后的更改确实修复了缺少地址的问题（#51747），但引入了一组新问题。可以通过创建 Sidecar 资源来解决原始问题。
  ([Issue #52944](https://github.com/istio/istio/issues/52944)),([Issue #52847](https://github.com/istio/istio/issues/52847))

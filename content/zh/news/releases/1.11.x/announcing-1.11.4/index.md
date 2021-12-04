---
title: 发布 Istio 1.11.4 版本
linktitle: 1.11.4
subtitle: 补丁发布
description: Istio 1.11.4 补丁发布。
publishdate: 2021-10-14
release: 1.11.4
aliases:
    - /zh/news/announcing-1.11.4
---

此版本包含一些漏洞修复，从而提高了系统的稳健性。这个版本说明描述了 Istio 1.11.3 和 Istio 1.11.4 之间的区别。

{{< relnote >}}

## 改变{#changes}

- **修复** 修复了 VMs 能够使用 `--revision` 在 `istioctl x workload entry`
命令上指定的修订控制平面的问题。

- **修复** 修复了同时创建 Service和 Gateway 导致服务被忽略的问题。
  ([Issue #35172](https://github.com/istio/istio/issues/35172))

- **修复** 修复了一个导致服务入口选择 pod 过时端点的问题。
  ([Issue #35404](https://github.com/istio/istio/issues/35404))

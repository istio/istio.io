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

- **修复** 修复了 VMs 通过在 `istioctl x workload entry` 命令中使用 `--revision` 参数
去使用修订版本控制平面的问题。

- **修复** 修复了同时创建 Service 和 Gateway 导致服务被忽略的问题。
  ([Issue #35172](https://github.com/istio/istio/issues/35172))

- **修复** 修复了由于 Service Entry 选择 Pod 时导致的 Endpoint 发送更新却无应答的问题。
  ([Issue #35404](https://github.com/istio/istio/issues/35404))

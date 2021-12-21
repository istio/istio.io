---
title: 发布 Istio 1.10.6 版本
linktitle: 1.10.6
subtitle: 补丁发布
description: Istio 1.10.6 补丁发布。
publishdate: 2021-11-29
release: 1.10.6
aliases:
    - /zh/news/announcing-1.10.6
---

此版本包含一些漏洞修复，从而提高了系统的稳健性。这个版本说明描述了 Istio 1.10.5 和 Istio 1.10.6 之间的区别。

{{< relnote >}}

## 改变{#changes}

- **修复** 修复了当 Istio 控制平面有活动代理连接时，阻止集群内运维人员删除资源的问题。
  ([Issue #35657](https://github.com/istio/istio/issues/35657))

- **Fixed** 修修复了在 k8s 1.21+ 版本中导致 `CronJob` 工作负载名称标准标签被错误填充的问题。
  ([Issue #35563](https://github.com/istio/istio/issues/35563))

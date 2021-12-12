---
title: Announcing Istio 1.10.6
linktitle: 1.10.6
subtitle: 补丁发布
description: Istio 1.10.6 补丁发布。
publishdate: 2021-11-29
release: 1.10.6
aliases:
    - /news/announcing-1.10.6
---

此版本包含错误修复以提高稳定性。 本发行说明描述了 Istio 1.10.5 和 Istio 1.10.6 之间的区别。

{{< relnote >}}

## Changes

- **修复** 当 Istio 控制平面连接活动代理时，阻止集群内操作员修剪资源的问题。
  ([Issue #35657](https://github.com/istio/istio/issues/35657))

- **修复** 导致 k8s 1.21+ 的 `CronJob` 的工作负载名称度量标签被错误填充的问题。
  ([Issue #35563](https://github.com/istio/istio/issues/35563))

---
title: Istio 1.12.7 发布公告
linktitle: 1.12.7
subtitle: 补丁发布
description: Istio 1.12.7 补丁发布。
publishdate: 2022-05-06
release: 1.12.7
aliases:
    - /zh/news/announcing-1.12.7
---

此版本包含错误修复，以提高系统的稳健性。同时本发布说明描述了 Istio 1.12.6 和 Istio 1.12.7 之间的不同之处。

{{< relnote >}}

## 改变{#changes}

- **新增** 新增了完全跳过 CNI 初始安装的支持。
  ([Pull Request #38158](https://github.com/istio/istio/pull/38158))

- **修复** 修复了当 Istio 控制平面有活动的代理连接时，集群内的 operator 无法削减资源的问题。
  ([Issue #35657](https://github.com/istio/istio/issues/35657))

- **修复** 修复了 webhook 分析中的一个问题，该问题会使 helm 调节器警告 webhook 的重复的问题。
  ([Issue #36114](https://github.com/istio/istio/issues/36114))

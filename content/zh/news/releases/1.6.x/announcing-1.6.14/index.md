---
title: 发布 Istio 1.6.14
linktitle: 1.6.14
subtitle: 补丁更新
description: Istio 1.6.14 补丁更新。
publishdate: 2020-11-23
release: 1.6.14
aliases:
    - /news/announcing-1.6.14
---

此版本包含修复错误以提高健壮性。这些发布说明描述了 Istio 1.6.13 和 Istio 1.6.14 之间的差异。

{{< relnote >}}

## 变更

- **修复** 遥测的 HPA 设置被内联副本覆盖的问题。
  ([Issue #28916](https://github.com/istio/istio/issues/28916))
- **修复** 在使用大量 ServiceEntries 时导致内存使用率非常高的问题。
  ([Issue #25531](https://github.com/istio/istio/issues/25531))
- **修复** Stackdriver 访问日志中缺少“用户代理”标头的问题。
  ([PR＃3083](https://github.com/istio/proxy/pull/3083))
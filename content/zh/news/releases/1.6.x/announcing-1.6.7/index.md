---
title: 发布 Istio 1.6.7
linktitle: 1.6.7
subtitle: 补丁更新
description: Istio 1.6.7 补丁更新。
publishdate: 2020-07-30
release: 1.6.7
aliases:
    - /news/announcing-1.6.7
---

此版本包含修复错误以提高健壮性。这些发布说明描述了 Istio 1.6.6 和 Istio 1.6.7 之间的差异。

{{< relnote >}}

## 变更

- **修复** 未关联到 Pod 的端点无法工作的问题。([Issue #25974](https://github.com/istio/istio/issues/25974))
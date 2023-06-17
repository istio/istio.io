---
title: 发布 Istio 1.6.13
linktitle: 1.6.13
subtitle: 补丁更新
description: Istio 1.6.13 补丁更新。
publishdate: 2020-10-27
release: 1.6.13
aliases:
    - /news/announcing-1.6.13
---

此版本包含修复错误以提高健壮性。这些发布说明描述了 Istio 1.6.12 和 Istio 1.6.13 之间的差异。

{{< relnote >}}

## 变更

- **修复** `cacert.pem` 在 `testdata` 目录下的问题。
  ([Issue #27574](https://github.com/istio/istio/issues/27574))

- **修复** Pilot代理应用探针连接泄露问题。
  ([Issue #27726](https://github.com/istio/istio/issues/27726))
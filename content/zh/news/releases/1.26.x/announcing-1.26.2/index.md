---
title: 发布 Istio 1.26.2
linktitle: 1.26.2
subtitle: 补丁发布
description: Istio 1.26.2 补丁发布。
publishdate: 2025-06-20
release: 1.26.2
aliases:
    - /zh/news/announcing-1.26.2
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.26.1 和 Istio 1.26.2 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了启用 TPROXY 模式时 OpenShift 上 `istio-proxy`
  和 `istio-validation` 容器的 UID 和 GID 分配不正确的问题。

- **修复** 修复了更改 `HTTPRoute` 对象可能导致 `istiod` 崩溃的问题。
  ([Issue #56456](https://github.com/istio/istio/issues/56456))

- **修复** 修复了 `istiod` 可能会错过 Kubernetes 对象状态更新的竞争条件的问题。
  ([Issue #56401](https://github.com/istio/istio/issues/56401))

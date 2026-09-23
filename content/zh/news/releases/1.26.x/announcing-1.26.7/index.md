---
title: 发布 Istio 1.26.7
linktitle: 1.26.7
subtitle: 补丁发布
description: Istio 1.26.7 补丁发布。
publishdate: 2025-12-03
release: 1.26.7
aliases:
    - /zh/news/announcing-1.26.7
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.26.6 和 Istio 1.26.7 之间的区别。

本次发布实现了 12 月 3 日公布的安全更新
[`ISTIO-SECURITY-2025-003`](/zh/news/security/istio-security-2025-003)。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了多集群中的 goroutine 泄漏问题，
  该问题会导致来自远程集群的数据的 krt 集合即使在集群被移除后仍会留在内存中。
  ([Issue #57269](https://github.com/istio/istio/issues/57269))

- **修复** 修复了当使用 `secret-name` 和 `namespace/secret-name` 格式从
  Istio Gateway 对象引用同一个 Kubernetes Secret 时，
  Envoy Secret 资源可能会卡在 `WARMING` 状态的问题。
  ([Issue #58146](https://github.com/istio/istio/issues/58146))

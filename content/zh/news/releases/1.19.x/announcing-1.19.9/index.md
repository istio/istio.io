---
title: 发布 Istio 1.19.9
linktitle: 1.19.9
subtitle: 补丁发布
description: Istio 1.19.9 补丁发布。
publishdate: 2024-04-08
release: 1.19.9
---

本次发布实现了 4 月 8 日公布的安全更新 [`ISTIO-SECURITY-2024-002`](/zh/news/security/istio-security-2024-002)
并修复了一些错误，提高了稳健性。

本发布说明描述了 Istio 1.19.8 和 Istio 1.19.9 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了更新 `ServiceEntry` 的 `TargetPort` 不会触发 xDS 推送的问题。
  ([Issue #49878](https://github.com/istio/istio/issues/49878))

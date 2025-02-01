---
title: 发布 Istio 1.22.8
linktitle: 1.22.8
subtitle: 补丁发布
description: Istio 1.22.8 补丁发布。
publishdate: 2025-01-22
release: 1.22.8
---

本发布说明描述了 Istio 1.22.7 和 Istio 1.22.8 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了 Ambient `PeerAuthentication` 策略过于严格的问题。
  ([Issue #53884](https://github.com/istio/istio/issues/53884))

- **修复** 修复了 Ambient 中的一个错误（仅限），
  其中 PeerAuthentication 策略中的多个 STRICT 端口级 mTLS 规则会由于不正确的评估逻辑（AND 与 OR）而有效地导致宽松的策略。
  ([Issue #54146](https://github.com/istio/istio/issues/54146))

- **修复** 修复了访问日志顺序不稳定导致连接耗尽的问题。
  ([Issue #54672](https://github.com/istio/istio/issues/54672))

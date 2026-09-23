---
title: 发布 Istio 1.23.5
linktitle: 1.23.5
subtitle: 补丁发布
description: Istio 1.23.5 补丁发布。
publishdate: 2025-02-13
release: 1.23.5
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.23.4 和 Istio 1.23.5 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了网关和 TLS 重定向中大小写混合 Host 导致 RDS 过时的错误。
  ([Issue #49638](https://github.com/istio/istio/issues/49638))

- **修复** 修复了 Ambient 模式 `PeerAuthentication` 策略过于严格的问题。
  ([Issue #53884](https://github.com/istio/istio/issues/53884))

- **修复** 修复了一个错误，即 Ambient 模式
  PeerAuthentication 策略中的多个 STRICT 端口级 mTLS
  规则由于不正确的评估逻辑（AND 与 OR）实际上会导致宽松的策略。
  ([Issue #54146](https://github.com/istio/istio/issues/54146))

- **修复** 修复了控制网关的非默认修订版本缺少 `istio.io/rev` 标签的问题。
  ([Issue #54280](https://github.com/istio/istio/issues/54280))

- **修复** 修复了访问日志顺序不稳定导致连接耗尽的问题。
  ([Issue #54672](https://github.com/istio/istio/issues/54672))

- **修复** 修复了 Istiod 会向 <1.23 代理发送不兼容的访问日志格式的错误。
  ([Issue #54795](https://github.com/istio/istio/issues/54795))

- **改进** 改进了 Istiod 的验证 webhook，以接受它不知道的版本。
  这确保较旧的 Istio 可以验证较新的 CRD 创建的资源。

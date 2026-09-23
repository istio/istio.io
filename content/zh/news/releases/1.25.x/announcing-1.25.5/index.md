---
title: 发布 Istio 1.25.5
linktitle: 1.25.5
subtitle: 补丁发布
description: Istio 1.25.5 补丁发布。
publishdate: 2025-09-03
release: 1.25.5
aliases:
    - /zh/news/announcing-1.25.5
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.25.4 和 Istio 1.25.5 之间的区别。

本次发布实现了 9 月 3 日公布的安全更新
[`ISTIO-SECURITY-2025-001`](/zh/news/security/istio-security-2025-001)。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了在决定是否需要应用新的 iptables 规则时，
  `istio-iptables` 有时会忽略 IPv4 状态而倾向于 IPv6 状态的问题。
  ([Issue #56587](https://github.com/istio/istio/issues/56587))

- **修复** 修复了一个错误，即我们的标签观察器代码没有将默认修订版本视为与默认标签相同。
  这会导致 Kubernetes 网关无法编程。
  ([Issue #56767](https://github.com/istio/istio/issues/56767))

- **修复** 修复了由于 JSON 模式验证器更严格导致使用 Helm v3.18.5 安装
  Gateway Chart 失败的问题。Chart 的模式已更新并兼容。
  ([Issue #57354](https://github.com/istio/istio/issues/57354))

- **修复** 修复了 `PreserveHeaderCase` 选项覆盖其他 HTTP/1.x 协议选项（例如 HTTP/1.0）的问题。
  ([Issue #57528](https://github.com/istio/istio/issues/57528))

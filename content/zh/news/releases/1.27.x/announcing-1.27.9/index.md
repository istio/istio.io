---
title: 发布 Istio 1.27.9
linktitle: 1.27.9
subtitle: 补丁发布
description: Istio 1.27.9 补丁发布。
publishdate: 2026-04-07
release: 1.27.9
aliases:
    - /zh/news/announcing-1.27.9
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.27.8 和 Istio 1.27.9 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了当集群中安装了高于最大支持版本的 CRD 版本时，
  istiod 启动失败的错误。目前支持 v1.4 及更低版本的 TLS 路由；v1.5 及更高版本将被忽略。
  ([Issue #59443](https://github.com/istio/istio/issues/59443))

- **修复** 修复了 `AuthorizationPolicy` 中的 `serviceAccount` 匹配正则表达式，
  现已能正确引用服务账号名称，从而确保能够正确匹配名称中包含特殊字符的服务账号。
  ([Issue #59700](https://github.com/istio/istio/issues/59700))

- **修复** 修复了 istiod 重启后所有网关（Gateways）均被重启的问题。
  ([Issue #59709](https://github.com/istio/istio/issues/59709))

- **修复** 修复了 `TLSRoute` 的主机名未被限制为与 `Gateway` 监听器主机名的交集这一问题。
  此前，当一个具有宽泛主机名（例如 `*.com`）的 `TLSRoute`
  绑定到一个具有较窄主机名（例如 `*.example.com`）的监听器上时，
  系统会错误地匹配该路由的完整主机名，而非仅匹配其交集（即 `*.example.com`），
  这与 Gateway API 规范的要求相悖。
  ([Issue #59229](https://github.com/istio/istio/issues/59229))

- **修复** 修复了一个竞态条件，该条件导致间歇性出现
  `proxy::h2 ping error: broken pipe` 错误日志。
  ([Issue #59192](https://github.com/istio/istio/issues/59192)),
  ([Issue #1346](https://github.com/istio/ztunnel/issues/1346))

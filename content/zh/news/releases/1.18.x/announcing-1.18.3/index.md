---
title: 发布 Istio 1.18.3
linktitle: 1.18.3
subtitle: 补丁发布
description: Istio 1.18.3 补丁发布。
publishdate: 2023-09-12
release: 1.18.3
---

该版本包含的错误修复用于提高稳健性。

本发布说明描述了 Istio 1.18.2 和 Istio 1.18.3 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **新增** 添加了可以通过 Helm Chart 方式安装具有双栈服务定义的网关功能。

- **修复** 修复了 HTTP 探针的 `request.host` 传播不畅的问题。
  ([Issue #46087](https://github.com/istio/istio/issues/46087))

- **修复** 修复了 `health_checkers` EnvoyFilter 扩展未编译到代理中的问题。
  ([Issue #46277](https://github.com/istio/istio/issues/46277))

- **修复** 修复了 Istio 应在 AWS 上尽可能使用 `IMDSv2` 的问题。
  ([Issue #45825](https://github.com/istio/istio/issues/45825))

- **修复** 修复了在没有任何提供程序的情况下创建 Telemetry 对象会引发 IST0157 错误的问题。
  ([Issue #46510](https://github.com/istio/istio/issues/46510))

- **修复** 修复了当只有默认提供程序时，`meshConfig.defaultConfig.sampling` 会被忽略的问题。
  ([Issue #46653](https://github.com/istio/istio/issues/46653))

- **修复** 修复了导致网格配置无法正确同步的问题，该问题通常会导致信任域配置错误。
  ([Issue #45739](https://github.com/istio/istio/issues/45739))

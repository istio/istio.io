---
title: Istio 1.12.3 版本发布
linktitle: 1.12.3
subtitle: 补丁发布
description: Istio 1.12.3 补丁发布。
publishdate: 2022-02-10
release: 1.12.3
aliases:
    - /zh/news/announcing-1.12.3
---

此版本包含漏洞修复，用以提高稳健性。本发行说明描述了 Istio 1.12.2 和 Istio 1.12.3 之间的不同之处。

{{< relnote >}}

## 变化{#changes}

- **修复** 修复了将服务的端点从 0 扩展到 1 可能导致客户端服务帐户验证填充不正确的问题。
  ([Issue #36456](https://github.com/istio/istio/issues/36456))

- **修复** 修复了在将 Istio 1.12 之前的版本升级到 1.12 时，代理将被注入两次，导致代理之间的 TCP 连接失败的问题。
  ([Issue #36797](https://github.com/istio/istio/pull/36797))

- **修复** 修复了如果在 Gateway 中配置了重复的密码套件，它们会被推送到 Envoy 配置的问题。使用此修复程序，
将忽略并记录重复的密码套件。
  ([Issue #36805](https://github.com/istio/istio/issues/36805))

- **修复** 修复了在给定的环境变量为布尔值或数值时，Helm 图表生成无效清单的问题。
  ([Issue #36946](https://github.com/istio/istio/issues/36946))

- **修复** 修复了为虚拟机创建配置文件时，json 编组处理后的生成错误格式的问题。
  ([Issue #36358](https://github.com/istio/istio/issues/36358))

- **修复** 修复了在 Gateway 中使用 `ISTIO_MUTUAL` TLS 模式的同时设置 `credentialName` 导致无法配置双向 TLS 的问题。此配置现在已被拒绝，因为 `ISTIO_MUTUAL` 本就是计划在未设置 `credentialName` 的情况下使用的。可以通过在 Istiod 中配置 `PILOT_ENABLE_LEGACY_ISTIO_MUTUAL_CREDENTIAL_NAME=true` 环境变量来保留旧的行为。

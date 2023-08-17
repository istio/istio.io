---
title: 发布 Istio 1.15.3
linktitle: 1.15.3
subtitle: 补丁发布
description: Istio 1.15.3 补丁发布。
publishdate: 2022-10-27
release: 1.15.3
---

此版本包含了一些改进稳健性的漏洞修复。本发布说明描述了 Istio 1.15.2 和 Istio 1.15.3 之间的不同之处。

{{< relnote >}}

## 变更{#changes}

- **更新** 更新了 `TRUSTED_GATEWAY_CIDR` 的默认值。先前此字段为空，会造成 XFCC 身份验证程序拒绝非环回请求。

- **新增** 当 `DestinationRule` 指定故障转移策略但未提供外部检测策略时增加了校验警告。先前 istiod 会以静默方式忽略故障转移设置。

- **修复** 修复了当设置 Pod 注解 `proxy.istio.io/config` 时会造成 `kube-inject` 崩溃的问题。

- **修复** 修复了配置 Datadog 跟踪提供程序时 Telemetry API 中缺少 `service_name` 的问题。([Issue #38573](https://github.com/istio/istio/issues/38573))

- **修复** 修复了不正确的架构配置导致 Istio Operator 进入错误循环的问题。 ([Issue #40876](https://github.com/istio/istio/issues/40876))

- **修复** 修复了网络端口转发支持 IPv4 和 IPv6 的问题。 ([Issue #40605](https://github.com/istio/istio/issues/40605))

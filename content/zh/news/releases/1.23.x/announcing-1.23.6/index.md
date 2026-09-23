---
title: 发布 Istio 1.23.6
linktitle: 1.23.6
subtitle: 补丁发布
description: Istio 1.23.6 补丁发布。
publishdate: 2025-04-07
release: 1.23.6
aliases:
    - /zh/news/announcing-1.23.6
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.23.5 和 Istio 1.23.6 之间的区别。

{{< relnote >}}

## 安全更新 {#security-updates}

- [CVE-2025-30157](https://nvd.nist.gov/vuln/detail/CVE-2025-30157)
  (CVSS Score 6.5, Medium): 当 HTTP `ext_proc` 处理本地回复时，Envoy 崩溃。

就 Istio 而言，此 CVE 仅在通过 `EnvoyFilter` 配置 `ext_proc` 的情况下可用。

## 变更 {#changes}

- **修复** 修复了由于 Envoy 引导程序未更新，导致通过
  `WORKLOAD_IDENTITY_SOCKET_FILE` 自定义工作负载身份 SDS 套接字名称不起作用的问题。
  ([Issue #51979](https://github.com/istio/istio/issues/51979))

- **修复** 修复了当 `meshConfig.accessLogEncoding` 设置为 `JSON` 时，
  Istiod 因代理 <1.23 的 LDS 错误而失败的问题。
  ([Issue #55116](https://github.com/istio/istio/issues/55116))

- **修复** 修复了 `gateway` 注入模板不遵循 `kubectl.kubernetes.io/default-logs-container`
  和 `kubectl.kubernetes.io/default-container` 注解的问题。

- **修复** 修复了验证 Webhook 拒绝原本有效的配置 `connectionPool.tcp.IdleTimeout=0s` 的问题。
  ([Issue #55409](https://github.com/istio/istio/issues/55409))

- **修复** 修复了当 `ServiceEntry` 使用 DNS 解析配置 `workloadSelector` 时，
  验证 Webhook 错误地报告警告的问题。
  ([Issue #50164](https://github.com/istio/istio/issues/50164))

- **修复** 修复了入口网关未使用 WDS 发现来检索 Ambient 目标的元数据的问题。

- **修复** 修复了 DNS 流量（UDP 和 TCP）现在受流量注释
  （如 `traffic.sidecar.istio.io/excludeOutboundIPRanges` 和
  `traffic.sidecar.istio.io/excludeOutboundPorts`）的影响。
  之前，由于规则结构的原因，即使指定了 DNS 端口，UDP/DNS 流量也会唯一地忽略这些流量注释。
  行为变化实际上发生在 1.23 版本系列中，但未包含在 1.23 的发行说明中。
  ([Issue #53949](https://github.com/istio/istio/issues/53949))

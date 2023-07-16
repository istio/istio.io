---
title: 发布 Istio 1.16.6
linktitle: 1.16.6
subtitle: 补丁发布
description: Istio 1.16.6 补丁发布。
publishdate: 2023-07-14
release: 1.16.6
---

该版本修复了于 7 月 14 日发布的 [ISTIO-SECURITY-2023-002](/zh/news/security/istio-security-2023-002)
中阐述的安全漏洞。

本发布说明描述了 Istio 1.16.5 和 Istio 1.16.6 之间的不同之处。
将于 2023 年 7 月 25 日或之后发布额外的安全版本，对应版本将修复众多安全缺陷，
其中最高级别安全缺陷的严重性为 High。欲了解更多信息，
请参阅[公告](https://discuss.istio.io/t/upcoming-istio-v1-18-1-v1-17-4-and-v1-16-6-security-releases/15864)。

{{< relnote >}}

## 安全更新 {#security-update}

- __[CVE-2023-35945](https://github.com/envoyproxy/envoy/security/advisories/GHSA-jfxv-29pc-x22r)__:
  (CVSS Score 7.5, High)：`nghttp2` 编解码器中的 HTTP/2 内存泄漏。

## 变更 {#changes}

- **新增** 在 Gateway Chart 中添加了对 `PodDisruptionBudget`（PDB）的支持。
  ([Issue #44469](https://github.com/istio/istio/issues/44469))

- **修复** 修复了 `istioctl proxy-config secret` 命令的证书有效性不准确的问题。

- **修复** 修复了当 DestinationRule 指定的证书无效时，CPU 使用率异常高的问题。
  ([Issue #44986](https://github.com/istio/istio/issues/44986))

- **修复** 修复了删除集群且禁用 xDS 缓存时 Istiod 可能崩溃的问题。
  ([Issue #45798](https://github.com/istio/istio/issues/45798))

- **修复** 修复了在错误报告中指定多个包含条件时 `--include` 无法按预期工作的问题。
  ([Issue #45839](https://github.com/istio/istio/issues/45839))

- **修复** 修复了通过 Istio 可观测 API 禁用日志提供程序时不生效的问题。

- **修复** 修复了除非明确指定 `match.metric=ALL_METRICS`，否则 `Telemetry`
  不会完全被禁用的问题；匹配所有指标现在可以被正确地当作默认值处理。

---
title: 发布 Istio 1.25.1
linktitle: 1.25.1
subtitle: 补丁发布
description: Istio 1.25.1 补丁发布。
publishdate: 2025-03-26
release: 1.25.1
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.25.0 和 Istio 1.25.1 之间的区别。

{{< relnote >}}

## 安全更新 {#security-updates}

- [CVE-2025-30157](https://nvd.nist.gov/vuln/detail/CVE-2025-30157)
  (CVSS Score 6.5, Medium): 当 HTTP `ext_proc` 处理本地回复时，Envoy 崩溃。

就 Istio 而言，此 CVE 仅在通过 `EnvoyFilter` 配置 `ext_proc` 的情况下可用。

## 变更 {#changes}

- **新增** 向 `HTTPRoute` 资源添加状态信息，
  以指示服务和服务条目资源的 `parentRefs` 的状态，
  以及在 Ambient 模式下指示 waypoint 配置状态的新条件。

- **修复** 修复了验证 Webhook 拒绝原本有效的配置 `connectionPool.tcp.IdleTimeout=0s` 的问题。
  ([Issue #55409](https://github.com/istio/istio/issues/55409))

- **修复** 修复了当 `ServiceEntry` 使用 DNS 解析配置 `workloadSelector` 时，
  验证 Webhook 错误地报告警告的问题。
  ([Issue #50164](https://github.com/istio/istio/issues/50164))

- **修复** 修复了由于引用相同 `parentRefs` 但不同 `sectionNames` 的逻辑复杂时发生崩溃，
  导致 `HTTPRoute` 状态未报告与单个结果相关联的 `parentRef` 的问题。

- **修复** 修复了 `IstioCertificateService`，以确保
  `IstioCertificateResponse.CertChain` 每个数组元素仅包含一个证书。
  ([Issue #1061](https://github.com/istio/ztunnel/issues/1061))

- **修复** 修复了如果端口未明确声明为 `http2`，则导致 waypoint 将 HTTP2 流量降级为 HTTP/1.1 的问题。

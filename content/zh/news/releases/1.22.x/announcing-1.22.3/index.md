---
title: 发布 Istio 1.22.3
linktitle: 1.22.3
subtitle: 补丁发布
description: Istio 1.22.3 补丁发布。
publishdate: 2024-07-16
release: 1.22.3
---

本发布说明描述了 Istio 1.22.2 和 Istio 1.22.3 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **更新** 更新了 Go 版本以包含与 [`CVE-2024-24791`](https://nvd.nist.gov/vuln/detail/CVE-2024-24791)
  相关的 net/http 包的安全修复程序

- **更新** 更新了 Envoy 版本以包含与
  [`CVE-2024-39305`](https://github.com/envoyproxy/envoy/security/advisories/GHSA-fp35-g349-h66f) 相关的安全修复

- **修复** 修复了在创建或更新服务时路由器的合并网关未立即重新计算的错误。
  ([Issue #51726](https://github.com/istio/istio/issues/51726))

- **修复** 修复了与 `istio_agent_cert_expiry_seconds` 指标不一致的行为。

- **移除** 删除了 JSON 访问日志的排序，等待 [Envoy 修复](https://github.com/envoyproxy/envoy/issues/34420)。

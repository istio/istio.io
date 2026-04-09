---
title: 发布 Istio 1.27.8
linktitle: 1.27.8
subtitle: 补丁发布
description: Istio 1.27.8 补丁发布。
publishdate: 2026-03-10
release: 1.27.8
aliases:
    - /zh/news/announcing-1.27.8
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.27.7 和 Istio 1.27.8 之间的区别。

{{< relnote >}}

## 安全更新 {#security-update}

如需了解更多信息，请参阅
[ISTIO-SECURITY-2026-001](/zh/news/security/istio-security-2026-001)。

### Envoy CVE {#envoy-cves}

- [CVE-2026-26308](https://nvd.nist.gov/vuln/detail/CVE-2026-26308) (CVSS score 7.5, High)：
  修复 RBAC 中的多值标头绕过问题。
- [CVE-2026-26311](https://nvd.nist.gov/vuln/detail/CVE-2026-26311) (CVSS score 5.9, Medium)：
  下游重置后，HTTP 解码方法被阻塞。
- [CVE-2026-26310](https://nvd.nist.gov/vuln/detail/CVE-2026-26310) (CVSS score 5.9, Medium)：
  修复 `getAddressWithPort()` 处理带作用域 IPv6 地址时发生的崩溃问题。
- [CVE-2026-26309](https://nvd.nist.gov/vuln/detail/CVE-2026-26309) (CVSS score 5.3, Medium)：
  修复 JSON 写入 "off-by-one" 错误。

### Istio CVE {#istio-cves}

- __[CVE-2026-31838](https://nvd.nist.gov/vuln/detail/CVE-2026-31838)__ / __[GHSA-974c-2wxh-g4ww](https://github.com/istio/istio/security/advisories/GHSA-974c-2wxh-g4ww)__: (CVSS score 6.9, Medium)：
  调试端点允许跨命名空间代理数据访问。
  由 [1seal](https://github.com/1seal) 报告。
- __[CVE-2026-31837](https://nvd.nist.gov/vuln/detail/CVE-2026-31837)__ / __[GHSA-v75c-crr9-733c](https://github.com/istio/istio/security/advisories/GHSA-v75c-crr9-733c)__: (CVSS score 8.7, High)：
  JWKS 解析器故障可能导致攻击者利用已知的默认密钥绕过身份验证。
  由 [1seal](https://github.com/1seal) 报告。

### Istio 安全修复 {#istio-security-fixes}

- **修复**：修复了要求明文端口 15010 上的 XDS 调试端点进行身份验证，
  以防止未经授权访问代理配置。由 [1seal](https://github.com/1seal) 报告。
- **修复** 修复了 `WasmPlugin` 图像抓取过程中潜在的 SSRF 漏洞，
  通过对 Bearer Token 的 Realm URL 进行验证来实现。
  由 [Sergey Kanibor (Luntry)](https://github.com/r0binak) 报告。
- **修复**：修复了端口 15014 上的 HTTP 调试端点，强制执行基于命名空间的授权，
  从而防止跨命名空间的代理数据访问。
  由 [Sergey Kanibor (Luntry)](https://github.com/r0binak) 报告。
- **新增** 添加了当 `ENABLE_DEBUG_ENDPOINT_AUTH=true` 时，
  允许为调试端点指定授权的命名空间。可通过将 `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES`
  设置为以逗号分隔的授权命名空间列表来启用此功能。
  系统命名空间（通常为 `istio-system`）始终处于授权状态。

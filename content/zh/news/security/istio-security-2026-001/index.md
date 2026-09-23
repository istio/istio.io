---
title: ISTIO-SECURITY-2026-001
subtitle: 安全公告
description: Envoy 和 Istio 安全修复所涉及的 CVE。
cves: [CVE-2026-26308, CVE-2026-26309, CVE-2026-26310, CVE-2026-26311, CVE-2026-26330, CVE-2026-31837, CVE-2026-31838]
cvss: "8.7"
vector: "CVSS:3.1/AV:N/AC:H/PR:N/UI:N/S:C/C:H/I:L/A:N"
releases: ["1.29.0", "1.28.0 to 1.28.4", "1.27.0 to 1.27.7"]
publishdate: 2026-03-10
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE {#envoy-cves}

- __[CVE-2026-26308](https://nvd.nist.gov/vuln/detail/CVE-2026-26308)__: (CVSS score 7.5, High)：
  修复了 RBAC 头部匹配器，使其能够逐一验证每个头部值，
  而非将多个头部值拼接成单个字符串。这有助于防止当请求中包含同一头部的多个值时可能出现的绕过风险。
- __[CVE-2026-26311](https://nvd.nist.gov/vuln/detail/CVE-2026-26311)__: (CVSS score 5.9, Medium)：
  修复了一个问题：在 HTTP 流已被重置但尚未销毁的情况下，过滤器链的执行可能会继续进行，
  从而潜在地引发“释放后使用”（use-after-free）的错误。
- __[CVE-2026-26310](https://nvd.nist.gov/vuln/detail/CVE-2026-26310)__: (CVSS score 5.9, Medium)：
  修复了在调用 `Utility::getAddressWithPort` 时，
  若传入带作用域的 IPv6 地址（例如 `fe80::1%eth0`）会导致程序崩溃的问题。
- __[CVE-2026-26309](https://nvd.nist.gov/vuln/detail/CVE-2026-26309)__: (CVSS score 5.3, Medium)：
  修复了 `JsonEscaper::escapeString()` 中的一处“差一”写入错误，该错误可能损坏字符串的空终止符。
- __[CVE-2026-26330](https://nvd.nist.gov/vuln/detail/CVE-2026-26330)__: (CVSS score 5.3, Medium)：
  修复了 gRPC 限流客户端中的一个 Bug，该 Bug 可能导致潜在的“释放后使用”（use-after-free）问题。
  仅影响 Istio 1.28 和 1.29 版本。

### Istio CVE {#istio-cves}

- __[CVE-2026-31838](https://nvd.nist.gov/vuln/detail/CVE-2026-31838)__ / __[GHSA-974c-2wxh-g4ww](https://github.com/istio/istio/security/advisories/GHSA-974c-2wxh-g4ww)__: (CVSS score 6.9, Medium)：
  调试端点允许跨命名空间代理数据访问。
  由 [1seal](https://github.com/1seal) 报告。
- __[CVE-2026-31837](https://nvd.nist.gov/vuln/detail/CVE-2026-31837)__ / __[GHSA-v75c-crr9-733c](https://github.com/istio/istio/security/advisories/GHSA-v75c-crr9-733c)__: (CVSS score 8.7, High)：
  JWKS 解析器故障可能导致攻击者利用已知的默认密钥绕过身份验证。
  由 [1seal](https://github.com/1seal) 报告。

### 其他 Istio 安全修复 {#other-istio-security-fixes}

- **修复**：修复了要求明文端口 15010 上的 XDS 调试端点进行身份验证，
  以防止未经授权访问代理配置。由 [1seal](https://github.com/1seal) 报告。
- **修复**：修复了 `WasmPlugin` 图像抓取过程中潜在的 SSRF 漏洞，
  通过对 Bearer Token 的 Realm URL 进行验证来实现。
  由 [Sergey Kanibor (Luntry)](https://github.com/r0binak) 报告。
- **修复**：修复了端口 15014 上的 HTTP 调试端点，强制执行基于命名空间的授权，
  从而防止跨命名空间的代理数据访问。
  由 [Sergey Kanibor (Luntry)](https://github.com/r0binak) 报告。

## 我受到影响了吗？{#am-i-impacted}

所有运行受影响 Istio 版本的用户均可能受到影响。

- 当授权策略基于可能包含多个值的请求头进行匹配时，Envoy RBAC
  请求头匹配漏洞便可被利用，从而导致策略绕过。

- JWKS 解析器漏洞可能导致身份验证绕过：当 JWKS 获取失败时，
  istiod 会回退至公开已知的默认密钥，攻击者可利用这些密钥伪造有效的 JWT。
  配置了 `jwksUri` 的 `RequestAuthentication` 资源用户将直接受到影响。

- XDS 调试端点漏洞允许未经身份验证的访问者通过明文 XDS
  端口 15010 访问调试端点（例如 `config_dump`），
  这可能导致敏感的代理配置信息泄露给任何能够通过网络访问 istiod 的工作负载。
  升级后，调试端点身份验证功能将默认启用。如有需要，您可以使用
  `ENABLE_DEBUG_ENDPOINT_AUTH` 和 `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` 这两个环境变量来调整配置，
  以确保与旧有系统的兼容性。

- `WasmPlugin` 镜像获取功能中的 SSRF 漏洞，
  可能允许攻击者将 Bearer Token 凭据重定向至任意 URL。

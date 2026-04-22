---
title: ISTIO-SECURITY-2026-003
subtitle: 安全公告
description: Istio 针对授权绕过和 SSRF 的安全修复。
cves: [CVE-2026-39350, CVE-2026-XXXXX]
cvss: "5.4"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:L/A:N"
releases: ["1.29.0 to 1.29.1", "1.28.0 to 1.28.5"]
publishdate: 2026-04-20
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Istio CVE {#istio-cve}

- __[CVE-2026-39350](https://nvd.nist.gov/vuln/detail/CVE-2026-39350)__ / __[GHSA-9gcg-w975-3rjh](https://github.com/istio/istio/security/advisories/GHSA-9gcg-w975-3rjh)__: (CVSS score 5.4, Moderate)：
  `AuthorizationPolicy` 的 `serviceAccounts` 字段存在正则表达式注入漏洞，起因是未转义的点号。
  由 [Wernerina](https://github.com/Wernerina) 报告。

- __[CVE-2026-41413](https://nvd.nist.gov/vuln/detail/CVE-2026-41413)__ / __[GHSA-fgw5-hp8f-xfhc](https://github.com/istio/istio/security/advisories/GHSA-fgw5-hp8f-xfhc)__: (CVSS score 5.0, Moderate)：
  通过 `RequestAuthentication` 的 `jwksUri` 导致的 SSRF 漏洞。
  由 [KoreaSecurity](https://github.com/KoreaSecurity)、
  [1seal](https://github.com/1seal) 和
  [AKiileX](https://github.com/AKiileX) 报告。

## 我受到影响了吗？{#am-i-impacted}

所有运行受影响 Istio 版本的用户均可能受到影响：

- 如果您使用了包含点号（`.`）的 `serviceAccounts` 字段的 `AuthorizationPolicy` 资源，
  则会受到**授权绕过**漏洞的影响。攻击者可以利用正则表达式通配符解析机制，
  通过使用特定命名的服务账号，绕过 `ALLOW` 策略或规避 `DENY` 策略。

- 如果您允许用户或自动化系统创建 `RequestAuthentication` 资源，
  则 **SSRF** 风险将具有实际影响。攻击者可以提供一个指向内部元数据服务或本地主机端口的 `jwksUri`，
  从而可能通过 xDS 配置将敏感的内部数据泄露给控制平面。

## 缓解措施 {#mitigation}

- 针对 Istio 1.29 用户：升级至 **1.29.2** 或更高版本。
- 针对 Istio 1.28 用户：升级至 **1.28.6** 或更高版本。

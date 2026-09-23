---
title: ISTIO-SECURITY-2025-003
subtitle: 安全公告
description: Envoy 上报的 CVE 漏洞。
cves: [CVE-2025-66220, CVE-2025-64527, CVE-2025-64763]
cvss: "8.1"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N"
releases: ["1.28.0", "1.27.0 to 1.27.3", "1.26.0 to 1.26.6"]
publishdate: 2025-12-03
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE {#envoy-cves}

- __[CVE-2025-66220](https://nvd.nist.gov/vuln/detail/CVE-2025-66220)__: (CVSS score 8.1, High)：`match_typed_subject_alt_names` 的 TLS
  证书匹配器可能会错误地将包含嵌入空字节的 `OTHERNAME` SAN 的证书视为有效证书。
- __[CVE-2025-64527](https://nvd.nist.gov/vuln/detail/CVE-2025-64527)__: (CVSS score 6.5, Medium)：当配置 JWT 身份验证并使用远程 JWKS 获取时，Envoy 崩溃。
- __[CVE-2025-64763](https://nvd.nist.gov/vuln/detail/CVE-2025-64763)__: (CVSS score 5.3, Medium)：CONNECT 升级后早期数据中可能存在请求走私的情况

## 我受到影响了吗？{#am-i-impacted}

如果您使用 Istio 接收 WebSocket 流量，则在 CONNECT 升级后，
您可能容易受到早期数据请求走私攻击。如果您使用带有 OTHERNAME SAN
的自定义证书或使用 `EnvoyFilter` 进行远程 JWKS 获取的自定义 JWT 身份验证，
也可能存在这种风险。

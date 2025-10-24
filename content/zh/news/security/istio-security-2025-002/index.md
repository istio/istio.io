---
title: ISTIO-SECURITY-2025-002
subtitle: 安全公告
description: Envoy 上报的 CVE 漏洞。
cves: [CVE-2025-55162, CVE-2025-54588]
cvss: "6.6"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.27.0 to 1.27.1", "1.26.0 to 1.26.5"]
publishdate: 2025-10-10
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE {#envoy-cves}

- __[CVE-2025-62504](https://nvd.nist.gov/vuln/detail/CVE-2025-62504)__:
  (CVSS score 6.5, Medium)：Lua 修改的响应体足够大会导致 Envoy 崩溃。
- __[CVE-2025-62409](https://nvd.nist.gov/vuln/detail/CVE-2025-62409)__:
  (CVSS score 6.6, Medium)：大量的请求和响应可能会导致 TCP 连接池崩溃。

## 我受到影响了吗？{#am-i-impacted}

如果您通过 `EnvoyFilter` 使用 Lua，并且返回的响应主体超过
`per_connection_buffer_limit_bytes`（默认为 1 MB），或者您有大量请求和响应，
而连接可以关闭但上游的数据仍在发送，那么您会受到影响。

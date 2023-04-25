---
title: ISTIO-SECURITY-2023-001
subtitle: 安全公告
description: Envoy 上报的众多 CVE 漏洞。
cves: [CVE-2023-27496, CVE-2023-27488, CVE-2023-27493, CVE-2023-27492, CVE-2023-27491, CVE-2023-27487]
cvss: "8.2"
vector: "CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:N"
releases: ["1.15.0 之前的所有版本", "1.15.0 到 1.15.6", "1.16.0 到 1.16.3", "1.17.0 到 1.17.1"]
publishdate: 2023-04-04
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs{#envoy-cves}

- __[CVE-2023-27487](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5375-pq35-hf2g)__:
  (CVSS Score 8.2, High)：客户端可能会伪造 `x-envoy-original-path` 头信息。

- __[CVE-2023-27488](https://github.com/envoyproxy/envoy/security/advisories/GHSA-9g5w-hqr3-w2ph)__:
  (CVSS Score 5.4, Moderate)：当收到具有非 UTF8 值的 HTTP 头信息时，gRPC 客户端会生成无效的 protobuf。

- __[CVE-2023-27491](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5jmv-cw9p-f9rp)__:
  (CVSS Score 5.4, Moderate)：Envoy 将转发无效的 HTTP/2 和 HTTP/3 下游头信息。

- __[CVE-2023-27492](https://github.com/envoyproxy/envoy/security/advisories/GHSA-wpc2-2jp6-ppg2)__:
  (CVSS Score 4.8, Moderate)：在 Lua 过滤器中处理大请求体时导致崩溃。

- __[CVE-2023-27493](https://github.com/envoyproxy/envoy/security/advisories/GHSA-w5w5-487h-qv8q)__:
  (CVSS Score 8.1, High)：Envoy 不会转义 HTTP 头信息的值。

- __[CVE-2023-27496](https://github.com/envoyproxy/envoy/security/advisories/GHSA-j79q-2g66-2xv5)__:
  (CVSS Score 6.5, Moderate)：在 OAuth 过滤器中收到没有 state 参数的重定向 URL 时导致崩溃。

## 我受到影响了吗？{#am-i-impacted}

如果您使用了 Istio Gateway 或者使用外部 istiod 可能面临风险。

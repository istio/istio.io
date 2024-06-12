---
title: ISTIO-SECURITY-2024-004
subtitle: 安全公告
description: Envoy 上报的 CVE 漏洞。
cves: [CVE-2024-32976, CVE-2024-32975, CVE-2024-32974, CVE-2024-34363, CVE-2024-34362, CVE-2024-23326, CVE-2024-34364]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.20.0 之前的所有版本", "1.20.0 到 1.20.6", "1.21.0 到 1.21.2", "1.22.0"]
publishdate: 2024-06-04
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE {#envoy-cves}

- __[CVE-2024-23326](https://github.com/envoyproxy/envoy/security/advisories/GHSA-vcf8-7238-v74c)__:
  (CVSS Score 5.9, Moderate)：对 HTTP/1 升级请求的响应处理不正确，可能导致请求走私。

- __[CVE-2024-32974](https://github.com/envoyproxy/envoy/security/advisories/GHSA-mgxp-7hhp-8299)__:
  (CVSS Score 5.9, Moderate)：QUIC 堆栈中的漏洞可能导致进程异常终止。

- __[CVE-2024-32975](https://github.com/envoyproxy/envoy/security/advisories/GHSA-g9mq-6v96-cpqc)__:
  (CVSS Score 5.9, Moderate)：QUIC 堆栈中的漏洞可能导致进程异常终止。

- __[CVE-2024-32976](https://github.com/envoyproxy/envoy/security/advisories/GHSA-7wp5-c2vq-4f8m)__:
  (CVSS Score 7.5, High)：`Brotli` 解压器中的漏洞可能导致无限循环。

- __[CVE-2024-34362](https://github.com/envoyproxy/envoy/security/advisories/GHSA-hww5-43gv-35jv)__:
  (CVSS Score 5.9, Moderate)：QUIC 堆栈中的漏洞可能导致进程异常终止。

- __[CVE-2024-34363](https://github.com/envoyproxy/envoy/security/advisories/GHSA-g979-ph9j-5gg4)__:
  (CVSS Score 7.5, High)：Envoy 访问日志 JSON 格式化程序中存在漏洞，可能导致进程异常终止。

- __[CVE-2024-34364](https://github.com/envoyproxy/envoy/security/advisories/GHSA-xcj3-h7vf-fw26)__:
  (CVSS Score 5.7, Moderate)：`ext_proc` 和 `ext_authz` 中的内存消耗不受限制。

## 我受到影响了吗？{#am-i-impacted}

如果您在 Istio 1.22 中使用 JSON 访问日志格式，则会受到影响，请尽快升级。请求走私也会影响 Websockets 的用户。

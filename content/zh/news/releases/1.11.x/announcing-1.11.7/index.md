---
title: Istio 1.11.7 发布公告
linktitle: 1.11.7
subtitle: 补丁发布
description: Istio 1.11.7 补丁发布。
publishdate: 2022-02-22
release: 1.11.7
aliases:
    - /zh/news/announcing-1.11.7
---

此版本修复了我们 2 月 22 日发布的 [ISTIO-SECURITY-2022-003](/zh/news/security/istio-security-2022-003)
中描述的安全漏洞。本发布说明描述了 Istio 1.11.6 和 Istio 1.11.7 之间的不同之处。

{{< relnote >}}

## 安全更新{#security-update}

- __[CVE-2022-23635](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2022-23635)__:
  CVE-2022-23635 (CVSS Score 7.5, High)：未经身份验证的控制平面拒绝服务攻击。

### Envoy CVE 漏洞{#envoy-cves}

目前不认为 Istio 容易受到 Envoy 中这些 CVE 漏洞的攻击。然而，它们被列出是为了披露。

- __[CVE-2021-43824](https://github.com/envoyproxy/envoy/security/advisories/GHSA-vj5m-rch8-5r2p)__:
  (CVSS Score 6.5, Medium)：使用 JWT 过滤器 `safe_regex` 匹配时可能会取消引用空指针。

- __[CVE-2021-43825](https://github.com/envoyproxy/envoy/security/advisories/GHSA-h69p-g6xg-mhhh)__:
  (CVSS Score 6.1, Medium)：当响应过滤器增加响应数据并且增加的数据超过下游缓冲区限制时产生 Use-after-free 结果。

- __[CVE-2021-43826](https://github.com/envoyproxy/envoy/security/advisories/GHSA-cmx3-fvgf-83mf)__:
  (CVSS Score 6.1, Medium)：如果下游在上游连接建立期间断开连接，
  则在通过 HTTP 隧道传输 TCP 时产生 Use-after-free 结果。

- __[CVE-2022-21654](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5j4x-g36v-m283)__:
  (CVSS Score 7.3, High)：不正确的配置处理允许 TLS 会话在验证设置更改后无需重新验证即可重用。

- __[CVE-2022-21655](https://github.com/envoyproxy/envoy/security/advisories/GHSA-7r5p-7fmh-jxpg)__:
  (CVSS Score 7.5, High)：对带有直接响应条目的路由的内部重定向处理不正确。

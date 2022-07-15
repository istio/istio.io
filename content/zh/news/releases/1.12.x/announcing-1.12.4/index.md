---
title: Istio 1.12.4 发布说明
linktitle: 1.12.4
subtitle: Patch Release
description: Istio 1.12.4 补丁发布。
publishdate: 2022-02-22
release: 1.12.4
aliases:
    - /zh/news/announcing-1.12.4
---

此版本修复了 2 月 22 日帖子中所述的安全漏洞 [ISTIO-SECURITY-2022-003](/zh/news/security/istio-security-2022-003)。此发布说明描述了 Istio 1.12.3 和 1.12.4 之间的不同之处。

{{< relnote >}}

## 安全更新 {#security-update}

- __[CVE-2022-23635](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2022-23635)__:
  CVE-2022-23635 (CVSS Score 7.5, High)：未经身份验证的控制面遭受拒绝服务攻击。

### Envoy CVE {#envoy-cves}

目前，人们认为 Istio 不会受到 Envoy 中这些 CVE 的攻击。然而还是将它们在下面列举出来，
以让 Istio 的使用者们都能够知道。

- __[CVE-2021-43824](https://github.com/envoyproxy/envoy/security/advisories/GHSA-vj5m-rch8-5r2p)__:
  (CVSS Score 6.5, Medium): 当使用 JWT 过滤器 `safe_regex` 匹配时可能会取消引用空指针。

- __[CVE-2021-43825](https://github.com/envoyproxy/envoy/security/advisories/GHSA-h69p-g6xg-mhhh)__:
  (CVSS Score 6.1, Medium): 当响应过滤器增加响应数据并且增加的数据超过下游缓冲区限制时，操作可能不会正确中止，并访问已释放的内存块。

- __[CVE-2021-43826](https://github.com/envoyproxy/envoy/security/advisories/GHSA-cmx3-fvgf-83mf)__:
  (CVSS Score 6.1, Medium): 如果在上游连接建立期间下游断开连接，则在通过 HTTP 隧道传输 TCP 时，操作可能不会正确中止，并访问已释放的内存块。

- __[CVE-2022-21654](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5j4x-g36v-m283)__:
  (CVSS Score 7.3, High): 不正确的配置处理允许 mTLS 会话在更改验证设置后无需重新验证即可重用。

- __[CVE-2022-21655](https://github.com/envoyproxy/envoy/security/advisories/GHSA-7r5p-7fmh-jxpg)__:
  (CVSS Score 7.5, High): 内部重定向到具有直接响应条目的路由的错误处理。

- __[CVE-2022-23606](https://github.com/envoyproxy/envoy/security/advisories/GHSA-9vp2-4cp7-vvxf)__:
  (CVSS Score 4.4, Moderate): 当通过 Cluster Discovery Service 删除集群时，堆栈耗尽。

# 变更 {#changes}

- **修复** 修复了服务更新不会触发路由更新的问题。
  ([Issue #37356](https://github.com/istio/istio/pull/37356))

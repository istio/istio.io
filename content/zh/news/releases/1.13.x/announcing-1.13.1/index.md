---
title: Istio 1.13.1 发布公告
linktitle: 1.13.1
subtitle: 补丁发布
description: Istio 1.13.1 补丁发布。
publishdate: 2022-02-22
release: 1.13.1
aliases:
    - /zh/news/announcing-1.13.1
---

此版本修复了我们在 2 月 22 日的文章中描述的安全漏洞，[ISTIO-SECURITY-2022-003](/zh/news/security/istio-security-2022-003)。这个发布说明描述了 Istio 1.13.0 和 1.13.1 之间的不同之处。

{{< relnote >}}

## 安全更新{#security-update}

- __[CVE-2022-23635](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2022-23635)__:
  CVE-2022-23635 (CVSS Score 7.5, High):  Istio 控制平面容易受到请求处理错误的影响，允许未经身份验证的恶意攻击者发送特制消息，从而导致控制平面崩溃。

### Envoy CVEs{#envoy-cves}

目前，人们认为 Istio 不会受到 Envoy 中这些 CVE 的攻击。然而还是将它们在下面列举出来，以让 Istio 的使用者们都能够知道。

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

# 改变{#changes}

- **修复** 修复了 `istioctl x describe svc` 无法正确评估 `appProtocol` 协议端口的问题。
  ([Issue #37159](https://github.com/istio/istio/issues/37159))

- **修复** 修复了服务更新不触发路由更新的问题。
  ([Issue #37356](https://github.com/istio/istio/pull/37356))

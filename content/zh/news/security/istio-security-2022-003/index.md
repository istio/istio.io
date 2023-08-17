---
title: ISTIO-SECURITY-2022-003
subtitle: 安全公告
description: Multiple CVEs related to istiod Denial of Service and Envoy.
cves: [CVE-2022-23635, CVE-2021-43824, CVE-2021-43825, CVE-2021-43826, CVE-2022-21654, CVE-2022-21655, CVE-2022-23606]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.11.0", "1.11.0 to 1.11.6", "1.12.0 to 1.12.3", "1.13.0"]
publishdate: 2022-02-22
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE{#CVE}

### CVE-2022-23635{#CVE-2022-23635}

- __[CVE-2022-23635](https://github.com/istio/istio/security/advisories/GHSA-856q-xv3c-7f2f)__:
  (CVSS 评分 7.5，高):  控制平面不能拒绝未经身份验证的服务攻击。

Istio 控制平面 istiod 容易受到请求处理错误的影响，允许恶意攻击者发送特制消息，
允许恶意攻击者发送特制消息，从而导致控制平面崩溃。此端点通过 TLS 15012 端口提供服务，
但不需要攻击者的任何身份验证。

对于简单的安装，istiod 通常只能从集群内访问，从而限制了受影响的半径。但是，对于某些部署，尤其是[多集群拓扑](/zh/docs/setup/install/multicluster/primary-remote/)，该端口会通过公网公开。

### Envoy CVEs{#envoy-cves}

目前，人们认为 Istio 不会受到 Envoy 中的这些 CVE 的攻击。然而，还是在下面把它们列出来了，
以让大家都了解。

| CVE ID                                                                                        | Score, Rating | 描述                                                                                                               | 在 1.13.1 中修复   | 在 1.12.4 中修复   | 在 1.11.7 中修复                 |
|-----------------------------------------------------------------------------------------------|---------------|---------------------------------------------------------------------------------------------------------------------------|-------------------|-------------------|----------------------------------|
| [CVE-2021-43824](https://github.com/envoyproxy/envoy/security/advisories/GHSA-vj5m-rch8-5r2p) | 6.5, 中   | 当使用 JWT 过滤器 `safe_regex` 匹配时，潜在的空指针取消引用。                                              | 是               | 是               | 是                              |
| [CVE-2021-43825](https://github.com/envoyproxy/envoy/security/advisories/GHSA-h69p-g6xg-mhhh) | 6.1, 中   | 当响应过滤器增加响应数据，并且增加的数据超出下游缓冲区限制时，需要释放内存后再使用。         | 是               | 是               | 是                              |
| [CVE-2021-43826](https://github.com/envoyproxy/envoy/security/advisories/GHSA-cmx3-fvgf-83mf) | 6.1, 中   | 当通过 HTTP 隧道传输 TCP时，如果在上游连接建立期间下游断开连接，则需要在释放内存后再使用。          | 是               | 是               | 是                              |
| [CVE-2022-21654](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5j4x-g36v-m283) | 7.3, 中     | 不正确的配置处理允许 mTLS 会话在更改验证设置后无需重新验证即可重用。
 | 是               | 是               | 是                              |
| [CVE-2022-21655](https://github.com/envoyproxy/envoy/security/advisories/GHSA-7r5p-7fmh-jxpg) | 7.5, 高     | 对带有直接响应条目的内部重定向路由的错误处理。                                          | 是               | 是               | 是                              |
| [CVE-2022-23606](https://github.com/envoyproxy/envoy/security/advisories/GHSA-9vp2-4cp7-vvxf) | 4.4, 中 | 当通过 Cluster Discovery Service 删除集群时，堆栈耗尽。                                                 | 是               | 是               | 不适用                              |
| [CVE-2022-21656](https://github.com/envoyproxy/envoy/security/advisories/GHSA-c9g7-xwcv-pjx2) | 3.1, 低      | X.509 `subjectAltName` 匹配（和 `nameConstraints`） 旁路。                                                           | 是               | 是               | Envoy 没有向后移植此修复程序。 |
| [CVE-2022-21657](https://github.com/envoyproxy/envoy/security/advisories/GHSA-837m-wjrv-vm5g) | 3.1, 低      | X.509 Extended Key Usage 和 Trust Purposes 旁路                                                                        | 不，下一个版本。 | 不，下一个版本。 | 不，下一个版本。                |

## 我受到影响了吗？{#am-i-impacted?}

如果您在多集群环境中运行 Istio，或者如果您已将 istiod 暴露在外部，那么您面临的风险最大。

## 赞扬{#credit}

我们要感谢 Adam Korczynski（[`ADA Logics`](https://adalogics.com)）和 John Howard（Google）的报告和修复。

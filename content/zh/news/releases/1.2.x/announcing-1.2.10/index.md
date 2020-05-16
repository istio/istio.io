---
title: Istio 1.2.10 发布公告
linktitle: 1.2.10
subtitle: 补丁发布
description: Istio 1.2.10 补丁发布。
publishdate: 2019-12-10
release: 1.2.10
aliases:
    - /zh/news/announcing-1.2.10
---

此版本包含了[我们在 2019 年 12 月 10 日新闻](/zh/news/security/istio-security-2019-007)中描述的安全漏洞的修复程序。此发行说明描述了 Istio 1.2.9 和 Istio 1.2.10 之间的区别。

{{< relnote >}}

## 安全更新{#security-update}

- **ISTIO-SECURITY-2019-007** 在 Envoy 中发现了堆溢出和不正确的输入验证。

__[CVE-2019-18801](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18801)__：修复了一个影响 Envoy 处理大型 HTTP/2 请求 header 的漏洞。成功利用此漏洞可能导致拒绝服务、特权提升或信息泄露。

__[CVE-2019-18802](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18802)__：修复了 HTTP/1 header 值后的空格引起的漏洞，该漏洞可能使攻击者绕过 Istio 的策略检查，从而可能导致信息泄露或特权提升。

## Bug 修复{#bug-fix}

- 添加对 Citadel 的支持以自动轮转根证书。（[Issue 17059](https://github.com/istio/istio/issues/17059)）

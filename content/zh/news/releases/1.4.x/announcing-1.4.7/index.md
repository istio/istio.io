---
title: Istio 1.4.7 发布公告
linktitle: 1.4.7
subtitle: 补丁发布
description: Istio 1.4.7 补丁发布。
publishdate: 2020-03-25
release: 1.4.7
aliases:
    - /zh/news/announcing-1.4.7
---

该版本修复了[我们2020年3月25日新闻帖子](/zh/news/security/istio-security-2020-004)中描述的安全漏洞。这个版本说明描述了 Istio 1.4.6 和 Istio 1.4.7 之间的区别。

{{< relnote >}}

## 安全更新{#Security-Update}

- **ISTIO-SECURITY-2020-004** Istio 为 Kiali 使用了一个硬编码的 `signing_key` 。

__[CVE-2020-1764](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-1764)__: Istio 使用默认的 `signing key` 来安装 Kiali。这允许访问 Kiali 的攻击者绕过身份验证并获得 Istio 的管理特权。
此外，在这个版本中还修复了另一个 CVE，在 Kiali 1.15.1 [版本](https://kiali.io/zh/news/security-bulletins/kiali-security-001/)中进行了描述。

## 改变{#changes}

- **修复** 修复了导致协议检测中中断网关的 HTTP2 流量的问题([Issue 21230](https://github.com/istio/istio/issues/21230)).

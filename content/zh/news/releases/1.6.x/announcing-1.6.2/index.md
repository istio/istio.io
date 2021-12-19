---
title: Istio 1.6.2 发布公告
linktitle: 1.6.2
subtitle: 补丁发布
description: Istio 1.6.2 安全补丁发布。
publishdate: 2020-06-11
release: 1.6.2
aliases:
    - /zh/news/announcing-1.6.2
---

这个版本修复了[我们 2020 年 6 月 11 日新闻帖子](/zh/news/security/istio-security-2020-006)中描述的安全漏洞。

同时这个版本说明也描述了 Istio 1.6.2 和 Istio 1.6.1 之间的区别。

{{< relnote >}}

## 安全更新{#security-update}

- **ISTIO-SECURITY-2020-006** 当处理带有大量参数的 HTTP/2 SETTINGS 帧时，由于 CPU 被占用过多，可能导致拒绝服务。

__[CVE-2020-11080](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-11080)__: 通过发送一个特制的数据包，攻击者可以使 CPU 的使用率达到 100% 的峰值。并且这个数据包还可以发送到入口网关或边车。

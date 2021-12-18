---
title: Istio 1.5.4 发布公告
linktitle: 1.5.4
subtitle: 补丁发布
description: Istio 1.5.4 安全补丁发布。
publishdate: 2020-05-13
release: 1.5.4
aliases:
    - /zh/news/announcing-1.5.4
---

该版本修复了我们在 [2020 年 5 月 12 日的新闻报道](/zh/news/security/istio-security-2020-005)中描述的安全漏洞。

这个版本说明描述了 Istio 1.5.4 和 Istio 1.5.3 之间的区别。

{{< relnote >}}

## 安全更新{#security-update}

- **ISTIO-SECURITY-2020-005** 启用 Telemetry V2 时拒绝服务。

__[CVE-2020-10739](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-10739)__: 通过发送一个特制的数据包，攻击者可以触发一个 Null Pointer Exception，从而导致 Denial of Service。并且这个数据包还可以发送到入口网关或边车。
---
title: Istio 1.5.9 发布公告
linktitle: 1.5.9
subtitle: 补丁发布
description: Istio 1.5.9 安全补丁发布。
publishdate: 2020-08-11
release: 1.5.9
aliases:
    - /zh/news/announcing-1.5.9
---

这个版本修复了[我们在 2020 年 8 月 11 日的新闻帖子](/zh/news/security/istio-security-2020-009)中描述的安全漏洞。

同时这些发布说明也描述了 Istio 1.5.8 和 Istio 1.5.9 之间的区别。

{{< relnote >}}

## 安全更新{#security-update}

- __[CVE-2020-16844](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-16844)__:
如果 TCP 服务的调用者定义了 Authorization Policies，并对源主体或名称空间字段使用了通配符后缀 (e.g. `*-some-suffix`) 来进行 `DENY` 操作，那么这个 TCP 服务的访问永远不会被拒绝。
    - CVSS Score: 6.8 [AV:N/AC:H/PR:L/UI:N/S:U/C:H/I:H/A:N](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:H/PR:L/UI:N/S:U/C:H/I:H/A:N&version=3.1)

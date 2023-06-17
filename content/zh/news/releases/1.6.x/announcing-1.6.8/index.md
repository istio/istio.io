---
title: 发布 Istio 1.6.8
linktitle: 1.6.8
subtitle: 补丁更新
description: Istio 1.6.8 补丁更新。
publishdate: 2020-08-11
release: 1.6.8
aliases:
    - /news/announcing-1.6.8
---

本版本修复了在[我们 2020年8月11日 的新闻帖子](/zh/news/security/istio-security-2020-009)中描述的安全漏洞。

此版本包含修复错误以提高健壮性。这些发布说明描述了 Istio 1.6.7 和 Istio 1.6.8 之间的差异。

{{< relnote >}}

## 安全更新

- __[CVE-2020-16844](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-16844)__:
对于定义了使用通配符后缀（例如 `*-some-suffix`）的源主体或名称空间字段的 `DENY` 操作的授权策略的 TCP 服务的调用方，将不会被拒绝访问。
    - CVSS评分：6.8 [AV:N/AC:H/PR:L/UI:N/S:U/C:H/I:H/A:N](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:H/PR:L/UI:N/S:U/C:H/I:H/A:N&version=3.1)
---
title: 发布 Istio 1.6.11
linktitle: 1.6.11
subtitle: 安全更新
description: Istio 1.6.11 安全更新。
publishdate: 2020-09-29
release: 1.6.11
aliases:
    - /news/announcing-1.6.11
---

本版本修复了在[我们 9月29日 的帖子](/zh/news/security/istio-security-2020-010)中描述的安全漏洞。

{{< relnote >}}

## 安全更新

- __[CVE-2020-25017](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-25017)__:
在某些情况下，Envoy 仅在存在多个标头时考虑第一个值。此外，Envoy 不会替换所有存在的非内联标头的出现。
    - __CVSS评分__：8.3 [AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L&version=3.1)
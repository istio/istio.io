---
title: 发布 Istio 1.7.3 版本
linktitle: 1.7.3
subtitle: 安全发布
description: Istio 1.7.3 安全发布。
publishdate: 2020-09-29
release: 1.7.3
aliases:
    - /zh/news/announcing-1.7.3
---

该版本修复了 [9 月 29 日帖子](/zh/news/security/istio-security-2020-010) 中，描述的安全漏洞。

{{< relnote >}}

## 安全更新{#security-update}

- __[CVE-2020-25017](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-25017)__：
在某些情况下，当存在多个头（Header）时，Envoy 只考虑第一个值。另外，Envoy 不会替换所有已存在的非内联头。
    - __CVSS Score__： 8.3 [AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L&version=3.1)

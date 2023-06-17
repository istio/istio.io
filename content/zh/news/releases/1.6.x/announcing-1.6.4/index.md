---
title: 发布 Istio 1.6.4
linktitle: 1.6.4
subtitle: 补丁更新
description: Istio 1.6.4 安全更新.
publishdate: 2020-06-30
release: 1.6.4
aliases:
    - /news/announcing-1.6.4
---

此版本解决了[我们 2020年6月30日 的安全公告](/zh/news/security/istio-security-2020-007)中描述的安全漏洞。

本版本说明介绍了 Istio 1.6.4 和 Istio 1.6.3 之间的差异。

{{< relnote >}}

## 安全更新

* __[CVE-2020-12603](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-12603)__：通过发送特殊制作的数据包，攻击者可以在代理 HTTP/2 请求或响应时导致 Envoy 消耗过多内存。
    * CVSS 评分: 7.0 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)

* __[CVE-2020-12605](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-12605)__：攻击者可以在处理特殊制作的 HTTP/1.1 数据包时导致 Envoy 消耗过多内存。
    * CVSS 评分：7.0 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)

* __[CVE-2020-8663](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8663)__：攻击者可以在接受过多连接时导致 Envoy 耗尽文件描述符。
    * CVSS 评分: 7.0 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)

* __[CVE-2020-12604](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-12604)__：攻击者可以在处理特殊制作的数据包时导致内存使用增加。
    * CVSS 评分：5.3 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:L](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)
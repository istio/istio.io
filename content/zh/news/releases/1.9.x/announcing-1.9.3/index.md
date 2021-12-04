---
title: 发布 Istio 1.9.3 版本
linktitle: 1.9.3
subtitle: 补丁发布
description: Istio 1.9.3 补丁发布。
publishdate: 2021-04-15
release: 1.9.3
aliases:
    - /zh/news/announcing-1.9.3
---

这个版本修复了[我们4月15日的帖子](/zh/news/security/istio-security-2021-003)中描述的安全漏洞。

{{< relnote >}}

## 安全更新{#security-update}

- __[CVE-2021-28683](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-28683)__:
Envoy 中包含一个远程可利用的 NULL 指针解引用，当接收到未知的 TLS 警报代码时，会导致 TLS 崩溃。
    - __CVSS Score__: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)
- __[CVE-2021-28682](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-28682)__:
Envoy 包含一个远程可利用的整数溢出，其中一个非常大的超时值会导致意外的超时计算。
    - __CVSS Score__: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)
- __[CVE-2021-29258](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-29258)__:
Envoy 包含一个远程可利用的漏洞，其中带有空元数据映射的 HTTP2 请求可能导致 Envoy 崩溃。
    - __CVSS Score__: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)

---
title: Istio 1.1.16 发布公告
linktitle: 1.1.16
subtitle: 发布补丁
description: Istio 1.1.16 版本发布公告。
publishdate: 2019-10-08
release: 1.1.16
aliases:
    - /zh/news/2019/announcing-1.1.16
    - /zh/news/announcing-1.1.16
---

我们很高兴地宣布 Istio 1.1.16 现在是可用的，详情请查看如下更改。

{{< relnote >}}

## 安全更新{#security-update}

此版本包含了我们在 [2019 年 10 月 8 日](/zh/news/security/istio-security-2019-005)的新闻中所阐述的修复程序的安全漏洞。特别是：

__ISTIO-SECURITY-2019-005__: `Envoy` 社区发现了一个 `DoS` 漏洞。
  * __[CVE-2019-15226](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-15226)__: 经过调查，`Istio` 团队发现，如果攻击者使用大量非常小的 `header`，则可以利用此问题进行对 `Istio` 的 `DoS` 攻击。

除了对上述程序的安全修复以外，此版本中不包含其他任何内容。

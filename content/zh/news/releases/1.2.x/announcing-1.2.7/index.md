---
title: 发布 Istio 1.2.7
linktitle: 1.2.7
subtitle: 发布补丁
description: Istio 1.2.7 版本修复。
publishdate: 2019-10-08
release: 1.2.7
aliases:
    - /zh/news/2019/announcing-1.2.7
    - /zh/news/announcing-1.2.7
---

我们很高兴地宣布 Istio 1.2.7 现在是可用的，详情请查看如下更改。

{{< relnote >}}

## 安全更新{#security-update}

此版本包含我们在 [2019 年 10 月 8 日](/zh/news/security/istio-security-2019-005)的新闻中所阐述的安全漏洞程序的修复。特别是：

__ISTIO-SECURITY-2019-005__:  `Envoy` 社区发现的一个 `DoS` 漏洞。
  * __[CVE-2019-15226](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-15226)__: 经过调查，`Istio` 团队发现，如果攻击者使用大量非常小的 `header`，则可以利用此问题在 `Istio` 中进行 `DoS` 攻击。

## Bug 修复{#bug-fix}

- 修复了 `nodeagent` 在使用 `citadel` 时启动失败的错误 ([Issue 15876](https://github.com/istio/istio/issues/17108))

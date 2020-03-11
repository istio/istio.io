---
title: Istio 1.3.2 发布公告
linktitle: 1.3.2
subtitle: 补丁发布
description: Istio 1.3.2 补丁发布。
publishdate: 2019-10-08
release: 1.3.2
aliases:
    - /zh/news/2019/announcing-1.3.2
    - /zh/news/announcing-1.3.2
---

我们很高兴地宣布 Istio 1.3.2 发布，请查看下面的更改说明。

{{< relnote >}}

## 安全更新{#security-update}

此版本包含我们 [2019 年 10 月 8 日新闻发布](/zh/news/security/istio-security-2019-005)中所述的安全漏洞修复程序。特别：

__ISTIO-SECURITY-2019-005__: Envoy 社区发现了一个 DoS 漏洞。
  * __[CVE-2019-15226](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-15226)__: 经过调查，Istio 团队发现，如果攻击者使用大量非常小的标头，则可以利用此问题进行 Istio 的 DoS 攻击。

除上述安全修复程序外，此版本中不包含其他任何内容。几天后将发布 Distroless 镜像。

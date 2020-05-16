---
title: Istio 1.3.8 发布公告
linktitle: 1.3.8
subtitle: 补丁发布
description: Istio 1.3.8 补丁发布。
publishdate: 2020-02-11
release: 1.3.8
aliases:
    - /zh/news/announcing-1.3.8
---

此版本包含了[我们在 2020 年 2 月 11 日的新闻](/zh/news/security/istio-security-2020-001)中描述的安全漏洞的修复程序。此发行说明描述了 Istio 1.3.7 和 Istio 1.3.8 之间的区别。

{{< relnote >}}

## 安全更新{#security-update}

- **ISTIO-SECURITY-2020-001** 在 `AuthenticationPolicy` 中发现了错误的输入验证。

__[CVE-2020-8595](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8595)__：Istio 的[认证策略](/zh/docs/reference/config/security/istio.authentication.v1alpha1/#Policy)精确路径匹配逻辑中的一个 bug，允许在没有效的 JWT 令牌、未经授权的情况下访问资源。

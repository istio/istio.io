---
title: ISTIO-SECURITY-2020-001
subtitle: 安全公告
description: 绕过身份认证策略。
cves: [CVE-2020-8595]
cvss: "9.0"
vector: "AV:N/AC:H/PR:N/UI:N/S:C/C:H/I:H/A:H"
releases: ["1.3 to 1.3.7", "1.4 to 1.4.3"]
publishdate: 2020-02-11
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Istio 1.3 到 1.3.7 以及 1.4 到 1.4.3 容易受到一个新发现漏洞的攻击，其会影响[认证策略](/zh/docs/reference/config/security/istio.authentication.v1alpha1/#Policy)：

* __[CVE-2020-8595](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8595)__：Istio 身份认证策略精确路径匹配逻辑中的一个 bug，允许在没有有效 JWT 令牌的情况下，对资源进行未经授权的访问。此 bug 会影响所有支持基于路径触发规则的 JWT 身份验证策略的 Istio 版本。Istio JWT 过滤器中用于精确路径匹配的逻辑包括查询字符串或片段，而不是在匹配之前将其剥离。这意味着攻击者可以通过在受保护的路径之后添加 `？` 或 `##` 字符来绕过 JWT 验证。

## 防范{#mitigation}

* 对于 Istio 1.3.x 部署: 请升级至 [Istio 1.3.8](/zh/news/releases/1.3.x/announcing-1.3.8) 或更高的版本。
* 对于 Istio 1.4.x 部署: 请升级至 [Istio 1.4.4](/zh/news/releases/1.4.x/announcing-1.4.4) 或更高的版本。

## 鸣谢{#credit}

Istio 团队在此对 [Aspen Mesh](https://aspenmesh.com/2H8qf3r) 的原始错误报告和 [CVE-2020-8595](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8595) 的修复代码表示感谢。

{{< boilerplate "security-vulnerability" >}}

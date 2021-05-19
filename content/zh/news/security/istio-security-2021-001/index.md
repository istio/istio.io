---
title: ISTIO-SECURITY-2021-001
subtitle: 安全公告
description: 滥用 AuthorizationPolicy 时，可以绕过 JWT 身份验证。
cves: [CVE-2021-21378]
cvss: "8.2"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:N"
releases: ["1.9.0"]
publishdate: 2021-03-01
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Envoy 和 Istio 容易受到新发现漏洞的攻击：

* __[CVE-2021-21378](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-21378)__:
  JWT 身份验证绕过未知的颁发者令牌
    * CVSS Score: 8.2 [AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:N](https://www.first.org/cvss/calculator/3.0#CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:N)

如果仅将 `RequestAuthentication` 用于 JWT 验证，则您会受到此漏洞的影响。

如果您同时使用 `RequestAuthentication` 和 `AuthorizationPolicy` 进行 JWT 验证，则您不受此漏洞的影响。

{{< warning >}}
请注意，`RequestAuthentication` 用于定义应接受的发行者列表。 它不会拒绝没有 JWT 令牌请求。
{{< /warning >}}

对于Istio，此漏洞仅在您的服务:

* 接受 JWT 令牌（带有 `RequestAuthentication`）
* 有一些未应用 `AuthorizationPolicy`的服务路径。

对于同时满足这两个条件的服务路径，带有 JWT 令牌且令牌发行者不在 `RequestAuthentication` 中的传入请求将绕过 JWT 验证，而不是被拒绝。

## 防范{#mitigation}

为了进行正确的 JWT 验证，您应该始终使用 istio.io 文档上记录的 `AuthorizationPolicy` 来[指定有效令牌](/zh/docs/tasks/security/authentication/authn-policy/#require-a-valid-token).
为此，您将必须审核所有 `RequestAuthentication` 和后续的 `AuthorizationPolicy` 资源，以确保它们与记录的实践保持一致。

{{< boilerplate "security-vulnerability" >}}

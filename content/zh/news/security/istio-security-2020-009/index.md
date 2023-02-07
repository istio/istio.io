---
title: ISTIO-SECURITY-2020-009
subtitle: 安全公告
description: TCP 服务的授权策略news/security/istio-security-2020-004/index.md中用于 Principals /名称空间的通配符后缀其 Envoy 配置不正确。
cves: [CVE-2020-16844]
cvss: "6.8"
vector: "AV:N/AC:H/PR:L/UI:N/S:U/C:H/I:H/A:N"
releases: ["1.5 to 1.5.8", "1.6 to 1.6.7"]
publishdate: 2020-08-11
keywords: [CVE]
skip_seealso: true
---
{{< security_bulletin >}}

Istio 容易受到新发现隐患的攻击：

* __[`CVE-2020-16844`](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-16844)__：对于源 Principals 和名称空间字段使用通配符后缀（例如：`* -some-suffix` ）的具有 `DENY` 操作的已定义授权策略TCP服务调用者，将永远不会被拒绝访问。
    * CVSS Score: 6.8 [AV:N/AC:H/PR:L/UI:N/S:U/C:H/I:H/A:N](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:H/PR:L/UI:N/S:U/C:H/I:H/A:N&version=3.1)

Istio 用户以下列方式容易受到此漏洞的影响：

如果用户具有类似于以下内容的授权

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: foo
 namespace: foo
spec:
 action: DENY
 rules:
 - from:
   - source:
       principals:
       - */ns/ns1/sa/foo # indicating any trust domain, ns1 namespace, foo svc account
{{< /text >}}

Istio 将 Principal (和 `source.principal`)字段转换为 Envoy 级别的字符串匹配。

{{< text yaml >}}
stringMatch:
  suffix: spiffe:///ns/ns1/sa/foo
{{< /text >}}

它将不匹配任何合法的调用者，因为它错误的包含了 `spiffe://` 字符串。正确的字符串匹配应该是：

{{< text yaml >}}
stringMatch:
  regex: spiffe://.*/ns/ns1/sa/foo
{{< /text >}}

`AuthorizationPolicy` 中的前缀和精确匹配不受影响，它们中的 `ALLOW` 操作也一样；HTTP 也不受影响。

## 防范{#mitigation}

* 对于 Istio 1.5.x 部署：请升级至 [Istio 1.5.9](/zh/news/releases/1.5.x/announcing-1.5.8) 或是更高的版本。
* 对于 Istio 1.6.x 部署：请升级至 [Istio 1.6.8](/zh/news/releases/1.6.x/announcing-1.6.8) 或是更高的版本。
* 不要在 TCP 服务的源 Principal 或名称空间字段的 `DENY` 策略中使用后缀匹配，并在适用的情况下使用前缀和精确匹配。 在可能的情况下，在您的服务中将 TCP 更改为 HTTP 作为端口名后缀。

{{< boilerplate "security-vulnerability" >}}

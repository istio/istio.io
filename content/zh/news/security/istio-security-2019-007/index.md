---
title: ISTIO-SECURITY-2019-007
subtitle: 安全公告
description: Envoy 中的堆溢出及错误的输入验证。
cves: [CVE-2019-18801,CVE-2019-18802]
cvss: "9.0"
vector: "CVSS:3.0/AV:N/AC:H/PR:N/UI:N/S:C/C:H/I:H/A:H"
releases: ["1.2 to 1.2.9", "1.3 to 1.3.5", "1.4 to 1.4.1"]
publishdate: 2019-12-10
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Envoy 及 Istio 容易受到基于两个新发现的漏洞的攻击:

* __[CVE-2019-18801](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18801)__：此漏洞以处理带有大量 HTTP/2 header 下游请求的方式影响 Envoy 的 HTTP/1 编解码器。利用此漏洞可能会导致拒绝服务、特权升级或信息泄露。

* __[CVE-2019-18802](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18802)__：HTTP/1 编解码器未能正确修剪 header 值的尾缀空格。这可能使攻击者可以绕开 Istio 的策略，导致特权升级或信息泄露。

## 影响范围{#impact-and-detection}

Istio gateway 和 sidecar 都容易受到此问题的影响。如果您正在运行受影响的发行版之一，其中下游的请求为 HTTP/2，而上游的请求为 HTTP/1，则您的群集很容易受到攻击。我们估计很多集群都是这样。

## 防范{#mitigation}

* 对于 Istio 1.2.x 部署: 请升级至 [Istio 1.2.10](/zh/news/releases/1.2.x/announcing-1.2.10) 或更高的版本。
* 对于 Istio 1.3.x 部署: 请升级至 [Istio 1.3.6](/zh/news/releases/1.3.x/announcing-1.3.6) 或更高的版本。
* 对于 Istio 1.4.x 部署: 请升级至 [Istio 1.4.2](/zh/news/releases/1.4.x/announcing-1.4.2) 或更高的版本。

{{< boilerplate "security-vulnerability" >}}

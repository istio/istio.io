---
title: ISTIO-SECURITY-2020-010
subtitle: 安全公告
description:
cves: [CVE-2020-25017]
cvss: "8.3"
vector: "AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L"
releases: ["1.6 to 1.6.10", "1.7 to 1.7.2"]
publishdate: 2020-09-29
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Envoy 及 Istio 容易受到新发现的漏洞的攻击:

- __[CVE-2020-25017](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-25017)__：
在某些情况下，Envoy 只会在出现多个（HTTP）头信息时考虑第一个值。而且 Envoy 不会替换所有存在的 non-inline（HTTP）头信息 。
    - __CVSS Score__：8.3 [AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L&version=3.1)

## 防范{#mitigation}

- 对于 Istio 1.6.x 部署： 请升级到 [Istio 1.6.11](/zh/news/releases/1.6.x/announcing-1.6.11) 或更高的版本。
- 对于 Istio 1.7.x 部署： 请升级到 [Istio 1.7.3](/zh/news/releases/1.7.x/announcing-1.7.3) 或更高的版本。

{{< boilerplate "security-vulnerability" >}}

---
title: ISTIO-SECURITY-2021-003
subtitle: 安全公告
description:
cves: [CVE-2021-28683, CVE-2021-28682, CVE-2021-29258]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.8.5", "1.9.0 to 1.9.2"]
publishdate: 2021-04-15
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Envoy 和 Istio 容易受到几个新发现的漏洞的攻击：

- __[CVE-2021-28683](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-28683)__：
Envoy 包含一个可远程利用的 NULL 指针取消引用，并在收到未知 TLS 警报代码时在 TLS 中崩溃。
    - __CVSS Score__: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)
- __[CVE-2021-28682](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-28682)__：
Envoy 包含一个可远程利用的整数溢出，其中非常大的 grpc-timeout 值会导致意外的超时计算。
    - __CVSS Score__: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)
- __[CVE-2021-29258](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-29258)__：
Envoy 包含一个可远程利用的漏洞，其中带有空元数据映射的 HTTP2 请求可能导致 Envoy 崩溃。
    - __CVSS Score__: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)

{{< boilerplate "security-vulnerability" >}}

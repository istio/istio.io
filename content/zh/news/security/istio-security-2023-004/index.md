---
title: ISTIO-SECURITY-2023-004
subtitle: 安全公告
description: Envoy 和 Go 上报的 CVE 漏洞。
cves: [CVE-2023-44487, CVE-2023-39325]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.17.0 以及之前的所有版本", "1.17.0 到 1.17.6", "1.18.0 到 1.18.3", "1.19.0 到 1.19.1"]
publishdate: 2023-10-11
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE

- __[`CVE-2023-44487`](https://nvd.nist.gov/vuln/detail/CVE-2023-44487)__: (CVSS Score 7.5, High)：
  HTTP/2 拒绝服务

### Go CVE

- __[`CVE-2023-39325`](https://github.com/golang/go/issues/63417)__: (CVSS Score 7.5, High)：
  HTTP/2 拒绝服务

## 我受到影响了吗？{#am-i-impacted}

如果您接受来自不受信来源的 HTTP/2 流量，则您会受到影响，这种情况适用于大多数用户。
如果您使用公共互联网上公开的网关，要特别注意您可能已经受到了影响。

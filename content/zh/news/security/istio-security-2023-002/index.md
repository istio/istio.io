---
title: ISTIO-SECURITY-2023-002
subtitle: 安全公告
description: Envoy 上报的 CVE 漏洞。
cves: [CVE-2023-35945]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.16.0 以及之前的所有版本", "1.16.0 到 1.16.5", "1.17.0 到 1.17.3", "1.18.0"]
publishdate: 2023-07-14
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE {#envoy-cves}

- __[CVE-2023-35945](https://github.com/envoyproxy/envoy/security/advisories/GHSA-jfxv-29pc-x22r)__:
  (CVSS Score 7.5, High)：`nghttp2` 编解码器中的 HTTP/2 内存泄漏。

## 我受到影响了吗？{#am-i-impacted}

如果您接受来自不受信来源的 HTTP/2 流量，这将适用于大多数用户。
如果您使用公共互联网上公开的网关，这一点尤其适用。

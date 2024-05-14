---
title: ISTIO-SECURITY-2024-003
subtitle: 安全公告
description: Envoy 上报的 CVE 漏洞。
cves: [CVE-2024-32475]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.19.0 之前的所有版本", "1.19.0 到 1.19.9", "1.20.0 到 1.20.5", "1.21.0 到 1.21.1"]
publishdate: 2024-04-22
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE {#envoy-cves}

- __[CVE-2024-32475](https://github.com/envoyproxy/envoy/security/advisories/GHSA-3mh5-6q8v-25wj)__:
  (CVSS Score 7.5, High)：使用 `auto_sni` 和 `:authority` 标头长度超过 255 个字符时出现异常终止。

## 我受到影响了吗？{#am-i-impacted}

如果您启用了 Envoy 的 `auto_sni` 功能，
使用的是默认启用此功能的 Istio 1.21.0 或更高版本，或者使用的是 Egress 网关，您会受到影响。

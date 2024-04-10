---
title: ISTIO-SECURITY-2024-002
subtitle: 安全公告
description: Envoy 和 Go 上报的 CVE 漏洞。
cves: [CVE-2024-27919, CVE-2024-30255, CVE-2023-45288]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.19.0 之前的所有版本", "1.19.0 到 1.19.8", "1.20.0 到 1.20.4", "1.21.0"]
publishdate: 2024-04-08
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE {#envoy-cves}

- __[CVE-2024-27919](https://github.com/envoyproxy/envoy/security/advisories/GHSA-gghf-vfxp-799r)__:
  (CVSS Score 7.5, High)：HTTP/2：由于 CONTINUATION 帧泛滥而导致内存耗尽。
- __[CVE-2024-30255](https://github.com/envoyproxy/envoy/security/advisories/GHSA-j654-3ccm-vfmm)__:
  (CVSS Score 5.3, Moderate)：HTTP/2：由于 CONTINUATION 帧泛滥而导致 CPU 耗尽。

### Go CVE {#go-cves}

**注意**：在发布时，该 CVE 尚未被评分或量化。

- __[CVE-2024-45288](https://nvd.nist.gov/vuln/detail/CVE-2023-45288)__:
  (CVSS Score Unpublished): HTTP/2 CONTINUATION 帧可被用于 DoS 攻击。

## 我受到影响了吗？{#am-i-impacted}

如果您接受来自不受信任来源的 HTTP/2 流量，您就会受到影响。
这适用于大多数用户。如果您使用公共互联网上公开的网关，这一点尤其适用。

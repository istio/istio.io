---
title: ISTIO-SECURITY-2025-001
subtitle: 安全公告
description: Envoy 上报的 CVE 漏洞。
cves: [CVE-2025-55162, CVE-2025-54588]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.27.0", "1.26.0 to 1.26.3", "1.25.0 to 1.25.4"]
publishdate: 2025-09-03
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE {#envoy-cves}

- __[CVE-2025-55162](https://github.com/envoyproxy/envoy/security/advisories/GHSA-95j4-hw7f-v2rh)__:
  (CVSS score 6.3, Moderate)：OAuth2 Filter Signout 路由由于缺少“secure;”标志将不会清除 Cookie
- __[CVE-2025-54588](https://github.com/envoyproxy/envoy/security/advisories/GHSA-g9vw-6pvx-7gmw)__:
  (CVSS score 7.5, High)：DNS 缓存释放后使用

## 我受到影响了吗？{#am-i-impacted}

如果您使用的是 Istio 1.27.0、1.26.0 至 1.26.3 或 1.25 至 1.25.4，
并且您使用以 `__Secure-` 或 `__Host-` 为前缀的 cookie，
或者您正在使用带有 `dynamic_forward_proxy` 的 `EnvoyFilter`，则将受到影响。

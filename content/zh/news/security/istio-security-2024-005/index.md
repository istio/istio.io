---
title: ISTIO-SECURITY-2024-005
subtitle: 安全公告
description: Envoy 上报的 CVE 漏洞。
cves: []
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.21.0 to 1.21.3", "1.22.0 to 1.22.1"]
publishdate: 2024-06-27
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE {#envoy-cves}

- __[GHSA-8mq4-c2v5-3h39](https://github.com/envoyproxy/envoy/security/advisories/GHSA-8mq4-c2v5-3h39)__:
  (CVSS Score 7.5, Moderate)：Datadog：Datadog 追踪器不处理带有 Unicode 字符标头的链路。

## 我受到影响了吗？{#am-i-impacted}

如果您使用 Istio 1.21.0 到 1.21.3 或 1.22.0 到 1.22.1 并且启用了 Datadog 追踪器，则会受到影响。

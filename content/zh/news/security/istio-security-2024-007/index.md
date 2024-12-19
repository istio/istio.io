---
title: ISTIO-SECURITY-2024-007
subtitle: 安全公告
description: Envoy 上报的 CVE 漏洞。
cves: [CVE-2024-53269, CVE-2024-53270, CVE-2024-53271]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.22.0 to 1.22.6", "1.23.0 to 1.23.3", "1.24.0 to 1.24.1"]
publishdate: 2024-12-18
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE {#envoy-cves}

- __[CVE-2024-53269](https://github.com/envoyproxy/envoy/security/advisories/GHSA-mfqp-7mmj-rm53)__:
  (CVSS Score 4.5, Moderate)：Happy Eyeballs：验证 `additional_address` 是否为 IP 地址，而不是在排序时崩溃。
- __[CVE-2024-53270](https://github.com/envoyproxy/envoy/security/advisories/GHSA-q9qv-8j52-77p3)__:
  (CVSS Score 7.5, High)：HTTP/1：当请求预先重置时，发送过载会导致崩溃。
- __[CVE-2024-53271](https://github.com/envoyproxy/envoy/security/advisories/GHSA-rmm5-h2wv-mg4f)__:
  (CVSS Score 7.1, High)：HTTP/1.1：`envoy.reloadable_features.http1_balsa_delay_reset` 存在多个问题。

## 我受到影响了吗？{#am-i-impacted}

如果您使用的是 Istio 1.22.0 至 1.22.6、1.23.0 至 1.23.3 或 1.24 至 1.24.1，
则将受到影响，请立即升级。如果您已创建自定义 `EnvoyFilter` 来启用过载管理器，
请避免使用 `http1_server_abort_dispatch` 负载削减点。

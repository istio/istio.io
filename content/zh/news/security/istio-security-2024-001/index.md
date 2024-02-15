---
title: ISTIO-SECURITY-2024-001
subtitle: 安全公告
description: Envoy 上报的 CVE 漏洞。
cves: [CVE-2024-23322, CVE-2024-23323, CVE-2024-23324, CVE-2024-23325, CVE-2024-23327]
cvss: "8.6"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:N/A:N"
releases: ["1.19.0 之前的所有版本", "1.19.0 到 1.19.6", "1.20.0 到 1.20.2"]
publishdate: 2024-02-09
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE {#envoy-cves}

**注意**：在本公告发布时，以下安全公告尚未被公布，但应该很快就会被公布。

- __[CVE-2024-23322](https://github.com/envoyproxy/envoy/security/advisories/GHSA-6p83-mfmh-qv38)__:
  (CVSS Score 7.5, High)：当空闲且在退避间隔内每次发生请求尝试超时，Envoy 会崩溃。
- __[CVE-2024-23323](https://github.com/envoyproxy/envoy/security/advisories/GHSA-x278-4w4x-r7ch)__:
  (CVSS Score 4.3, Moderate)：使用正则表达式配置 URI 模板匹配器时 CPU 使用率过高。
- __[CVE-2024-23324](https://github.com/envoyproxy/envoy/security/advisories/GHSA-gq3v-vvhj-96j6)__:
  (CVSS Score 8.6, High)：当代理协议过滤器设置无效的 UTF-8 元数据时，可以绕过外部身份验证。
- __[CVE-2024-23325](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5m7c-mrwr-pm26)__:
  (CVSS Score 7.5, High)：当使用的操作系统不支持地址类型时，Envoy 会崩溃。
- __[CVE-2024-23327](https://github.com/envoyproxy/envoy/security/advisories/GHSA-4h5x-x9vh-m29j)__:
  (CVSS Score 7.5, High)：当命令类型为 LOCAL 时，代理协议崩溃。

## 我受到影响了吗？{#am-i-impacted}

大多数可利用行为与 PROXY 协议的使用有关，主要被使用于网关场景。
如果您或您的用户通过 `EnvoyFilter` 或[代理配置](/zh/docs/ops/configuration/traffic-management/network-topologies/#proxy-protocol)注解启用了 PROXY 协议，
则存在潜在的暴露风险。

除了使用 PROXY 协议之外，对于访问日志使用 `%DOWNSTREAM_PEER_IP_SAN%`
[命令运算符](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage.html#command-operators)有潜在的暴露风险。

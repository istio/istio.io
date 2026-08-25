---
title: ISTIO-SECURITY-2026-004
subtitle: 安全公告
description: Envoy 报告的 CVE。
cves: [CVE-2026-47774]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.30.0", "1.29.0 to 1.29.3", "1.28.0 to 1.28.7"]
publishdate: 2026-06-04
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE {#envoy-cves}

- [CVE-2026-47774](https://github.com/envoyproxy/envoy/security/advisories/GHSA-22m2-hvr2-xqc8) (CVSS score 7.5, High)：
  未经身份验证的远程攻击者可能会耗尽 Envoy 进程中的内存，从而导致拒绝服务。
  在请求标头大小验证期间未完全考虑 Cookie 标头字节，
  并且对编码字节强制执行 HPACK 标头块限制，而对总解码标头大小没有相应限制，
  从而允许攻击者通过特制的 HTTP/2 请求触发过多的内存消耗。

## 我受到影响了吗？{#am-i-impacted}

如果您运行受影响的 Istio 版本并接受下游 HTTP/2 流量，您就会受到影响。
这包括通过 HTTP/2 或 gRPC 向外部客户端或不受信任的工作负载公开服务的任何 Istio 部署，
因为攻击者可以发送带有大 Cookie 标头的特制请求以触发过多的内存消耗。

## 缓解措施 {#mitigation}

- 针对 Istio 1.30 用户：升级至 **1.30.1** 或更高版本。
- 针对 Istio 1.29 用户：升级至 **1.29.4** 或更高版本。
- 针对 Istio 1.28 用户：升级至 **1.28.8** 或更高版本。

---
title: ISTIO-SECURITY-2022-007
subtitle: 安全公告
description: 由于 Go 语言正则表达式库造成拒绝服务 (DoS) 攻击。
cves: [CVE-2022-39278]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.13 之前的所有版本", "1.13.0 到 1.13.8", "1.14.0 到 1.14.4", "1.15.0 到 1.15.1"]
publishdate: 2022-10-12
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-39278

- __[CVE-2022-39278](https://github.com/istio/istio/security/advisories/GHSA-86vr-4wcv-mm9w)__:
  (CVSS Score 7.5, High)：由于 Go 语言正则表达式库造成拒绝服务 (DoS) 攻击。

Istio 控制平面 Istiod 容易受到请求处理错误的影响，允许恶意攻击者发送特制或超大的消息，这样会使控制平面进程崩溃。
当以公开方式暴露 Kubernetes 校验或更改 Webhook 服务时，此漏洞可能被人利用。
此端点通过 TLS 端口 15017 提供服务，但不需要攻击者进行任何身份验证。

对于简单的安装，Istiod 通常只能从集群内部访问，这限制了受影响的范围。
但是，对于某些 Deployment，尤其是控制平面运行在不同的集群中时，此端口会被暴露在公网上。

### Go CVE

以下 Go 问题指向由 Go 正则表达式库引起的安全漏洞。它在 Go 1.18.7 和 Go 1.19.2 中得到了公开的修复。

- [CVE-2022-41715](https://github.com/golang/go/issues/55949)

## 我受到影响了吗？{#am-i-impacted}

如果您正在外部 istiod 环境中运行 Istio，或已经向外暴露了 Istiod 且正在使用任一受影响的 Istio 版本，那么您面临的风险很大。

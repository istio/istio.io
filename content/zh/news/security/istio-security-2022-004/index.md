---
title: ISTIO-SECURITY-2022-004
subtitle: 安全公告
description: 由于堆栈耗尽，控制平面不能拒绝未经身份验证的服务攻击。
cves: [CVE-2022-24726, CVE-2022-24921]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.11.0", "1.11.0 to 1.11.7", "1.12.0 to 1.12.4", "1.13.0 to 1.13.1"]
publishdate: 2022-03-09
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE{#cve}

### CVE-2022-24726{#cve-2022-24726}

- __[CVE-2022-24726](https://github.com/istio/istio/security/advisories/GHSA-8w5h-qr4r-2h6g)__:
  (CVSS Score 7.5, High)：由于堆栈耗尽导致未经身份验证的控制平面拒绝服务攻击。

Istio 控制平面 istiod 容易受到请求处理错误的影响，允许恶意攻击者发送特制消息， 允许恶意攻击者发送特制或者过大的消息
 从而导致控制平面进程崩溃。当 Kubernetes validating 或 mutating webhook 服务被公开时，这可能被利用。 此端点通过 TLS 15017 端口提供服务， 但不需要攻击者的任何身份验证。

对于简单的安装，istiod 通常只能从集群内访问，从而限制了受影响的半径。 但是，对于某些部署，尤其是那些控制平面在不同集群中的部署，该端口会通过公网公开。

由于Golang团队发布了CVE-2022-24921，Istio认为这是一个0天漏洞。

### Envoy CVEs{#envoy-cves}

Envoy 的以下 Envoy CVE 也针对 Istio 1.11.8、1.12.5 和 Istio 1.13.2 进行了修补。 它们已在 https://github.com/envoyproxy/envoy 中公开修复，用于先前 Istio 版本中使用的 Envoy 版本。 如 ISTIO-SECURITY-2022-003 中所述，Istio 不易受到攻击。

- __[CVE-2022-21657](https://github.com/envoyproxy/envoy/security/advisories/GHSA-837m-wjrv-vm5g)__
 (CVSS Score 3.1, Low)：X.509 Extended Key Usage 和 Trust Purposes 旁路。

在Istio 1.12.5和Istio 1.13.2中也修复了以下问题。

- __[CVE-2022-21656](https://github.com/envoyproxy/envoy/security/advisories/GHSA-c9g7-xwcv-pjx2)__
 (CVSS Score 3.1, Low)：X.509 主题替代名称（和名称约束）匹配旁路。

## 我受到影响了吗？{#am-i-impacted?}

如果您在外部istiod环境中运行 Istio，或者您将您的 istiod 暴露在外部，那么您的风险最大。

## 赞扬{#credit}

我们要感谢 John Howard (Google) 的报告和修复。

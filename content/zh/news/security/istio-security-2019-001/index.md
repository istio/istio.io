---
title: ISTIO-SECURITY-2019-001
subtitle: 安全公告
description: 错误的权限控制。
cve: [CVE-2019-12243]
publishdate: 2019-05-28
keywords: [CVE]
skip_seealso: true
aliases:
    - /zh/blog/2019/cve-2019-12243
    - /zh/news/2019/cve-2019-12243
---

{{< security_bulletin
        cves="CVE-2019-12243"
        cvss="8.9"
        vector="CVSS:3.0/AV:A/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:N/E:H/RL:O/RC:C"
        releases="1.1 to 1.1.6" >}}

## 内容{#context}

在检视 [Istio 1.1.7](/zh/news/releases/1.1.x/announcing-1.1.7) 发布公告时我们发现已修复的缺陷 [issue 13868](https://github.com/istio/istio/issues/13868) 隐含一个安全漏洞。

起初我们认为该缺陷仅影响 alpha 特性 [TCP Authorization](/zh/about/feature-stages/#security-and-policy-enforcement)，这样就不需要安全公告。但后来我们发现稳定特性
[Deny Checker](/zh/docs/reference/config/policy-and-telemetry/adapters/denier/)、
[List Checker](/zh/docs/reference/config/policy-and-telemetry/adapters/list/) 也受到影响。
我们正在重新评估标识缺陷为安全漏洞的流程而不是通过
[private disclosure process](/zh/about/security-vulnerabilities/)。

该缺陷源于 Istio 1.1 中引入的一个代码变更，影响至 1.1.6 的所有版本。

## 影响与检测{#impact-and-detection}

从 Istio 1.1 版本起，Istio 默认安装时策略增强是关闭的。

您可以通过以下命令来检测服务网格策略增强状态：

{{< text bash >}}
$ kubectl -n istio-system get cm istio -o jsonpath="{@.data.mesh}" | grep disablePolicyChecks
disablePolicyChecks: true
{{< /text >}}

如果 `disablePolicyChecks` 状态为 true 那意味着该漏洞对您没有影响。

如果以下条件都是 true 那意味着该漏洞对您有影响：

* 您在使用受影响的 Istio 版本
* `disablePolicyChecks` 设置为 false（请使用上述命令检查）
* 您的工作负载未使用 HTTP、HTTP/2 或 gRPC 协议
* 使用 Mixer 适配器（比如 Deny Checker、List Checker）来为您的后端 TCP 服务提供授权。

## 防范{#mitigation}

* Istio 1.0.x 用户未受影响。
* 对 Istio 1.1.x 部署请升级至 [Istio 1.1.7](/zh/news/releases/1.1.x/announcing-1.1.7) 或后续版本。

## 致谢{#credit}

Istio 团队非常感谢 `Haim Helman` 报告该缺陷。

{{< boilerplate "security-vulnerability" >}}

---
title: ISTIO-SECURITY-2020-002
subtitle: 安全公告
description: 由于不正确地接受某些请求 header 导致 Mixer 策略检查被绕过。
cves: [CVE-2020-8843]
cvss: "7.4"
vector: "AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:H/A:N"
releases: ["1.3 to 1.3.6"]
publishdate: 2020-02-11
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Istio 1.3 到 1.3.6 包含了影响 Mixer 策略检查的漏洞。

注意：我们在 Istio 1.4.0 以及 Istio 1.3.7 中默认地修复了该漏洞。
Istio 1.4.0 中的一个 [问题](https://github.com/istio/istio/issues/12063) 及其 [修复](https://github.com/istio/istio/pull/17692) 是一个非安全性问题。我们在 2019 年 12 月将该问题重新分类为漏洞。
__[CVE-2020-8843](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8843)__：在某些情况下，可以绕过特定配置的 Mixer 策略。Istio-proxy 在 ingress 处接受 `x-istio-attributes` header，当 Mixer 策略有选择地应用至 source 时，等价于应用至 ingress，其可能会影响策略决策。
为了避免这种情况，Istio 必须启用并以指定方式使用 Mixer 策略。在 Istio 1.3 和 1.4 中，默认情况下未启用此功能。

## 防范{#mitigation}

* 对于 Istio 1.3.x 部署: 请升级至 [Istio 1.3.7](/zh/news/releases/1.3.x/announcing-1.3.7) 或更高的版本。

## 鸣谢{#credit}

Istio 团队在此对 [Splunk](https://www.splunk.com/) 的 Krishnan Anantheswaran 和 Eric Zhang 提供的私人 bug 报告表示感谢。

{{< boilerplate "security-vulnerability" >}}

---
title: ISTIO-SECURITY-2020-005
subtitle: 安全公告
description: 影响 telemetry v2 的拒绝服务漏洞。
cves: [CVE-2020-10739]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.4 to 1.4.8", "1.5 to 1.5.3"]
publishdate: 2020-05-12
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## 内容{#context}

启用 telemetry v2 的 Istio 1.4 和启用了 telemetry v2 的 Istio 1.5 包含以下漏洞：

* __[CVE-2020-10739](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-10739)__:
通过发送特制数据包，攻击者可能会触发空指针异常，从而导致拒绝服务。这可以发送到 ingress gateway 或 sidecar。
    * CVSS Score: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:A/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:N&version=3.1)

## 防范{#mitigation}

* 对于 Istio 1.4.x 部署：请升级至 Istio 1.4.9 或更高的版本。
* 对于 Istio 1.5.x 部署：请升级至 Istio 1.5.4 或更高的版本。
* 解决方法：或者，您可以通过运行以下命令禁用 telemetry v2：

{{< text bash >}}
$ istioctl manifest apply --set values.telemetry.v2.enabled=false
{{< /text >}}

## 致谢{#credit}

我们在此对 `Joren Zandstra` 的的原始错误报告表示感谢。

{{< boilerplate "security-vulnerability" >}}

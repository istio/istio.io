---
title: ISTIO-SECURITY-2022-006
subtitle: 安全公告
description: 在某些配置中，发送给 Envoy 的格式错误的标头可能会导致意外的内存访问，从而导致未定义的行为或崩溃。
cves: [CVE-2022-31045]
cvss: "5.9"
vector: "CVSS:3.1/AV:N/AC:H/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.13.6", "1.14.2"]
publishdate: 2022-07-26
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## 不要使用 Istio 1.14.2 和 Istio 1.13.6{#do-not-use-istio-1.14.2-and-istio-1.13.}

由于流程问题，[CVE-2022-31045](/zh/news/security/istio-security-2022-005/#cve-2022-31045)未包含在我们的 Istio 1.14.2 和 Istio 1.13.6 构建中。

此时我们建议您不要在生产环境中安装 1.14.2 或 1.13.6。如果您已安装，您可以降级到 Istio 1.14.1 或 Istio 1.13.5。Istio 1.14.3 和 Istio 1.13.7 预计将在本周晚些时候发布。

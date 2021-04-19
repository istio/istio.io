---
title: ISTIO-SECURITY-2020-008
subtitle: 安全公告
description: 通配符 DNS 使用者主机名称的验证不正确。
cves: [CVE-2020-15104]
cvss: "6.6"
vector: "AV:N/AC:H/PR:H/UI:N/S:C/C:H/I:L/A:N/E:F/RL:O/RC:C"
releases: ["1.5 to 1.5.7", "1.6 to 1.6.4", "All releases prior to 1.5"]
publishdate: 2020-07-09
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Istio 容易受到新发现漏洞的攻击:

* __[`CVE-2020-15104`](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-15104)__:
当验证 TLS 证书时，Envoy 错误地允许将通配符 DNS 使用者主机名称应用于多个子域。例如，在 SAN 为 `*.example.com` 通配的情况下，Envoy 错误地允许使用 `nested.subdomain.example.com`，而它只允许使用 `subdomain.example.com`。
    * CVSS Score: 6.6 [AV:N/AC:H/PR:H/UI:N/S:C/C:H/I:L/A:N/E:F/RL:O/RC:C](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:H/PR:H/UI:N/S:C/C:H/I:L/A:N/E:F/RL:O/RC:C&version=3.1)

Istio 用户通过以下方式暴露此漏洞:

* 通过 [Envoy 筛选器](/zh/docs/reference/config/networking/envoy-filter/)直接使用 Envoy 的`verify_subject_alt_name`和`match_subject_alt_names`配置。

* 使用Istio 的[`subjectAltNames`字段在目标规则与客户端 TLS 设置](/zh/docs/reference/config/networking/destination-rule/#ClientTLSSettings)。具有包含`nested.subdomain.example.com` 的 `subjectAltNames` 字段的目标规则错误地接受来自主机名称（SAN）为`*.example.com`的上游层证书。 相反，应该存在一个`*.subdomain.example.com`或`nested.subdomain.example.com`的 SAN。

* 使用 Istio 的[服务条目中的`subjectAltNames`](/zh/docs/reference/config/networking/service-entry/)。带有`subjectAltNames`字段的值类似于`nested.subdomain.example.com`的服务条目错误地接受来自 SAN 为`*.example.com` 的上游层证书。

Istio CA（以前称为 Citadel）不使用 DNS 通配符 SAN 颁发证书。 该漏洞仅影响验证外部颁发证书的配置。

## 防范{#mitigation}

* 对于 1.5.x deployments: 部署： 请升级至 [Istio 1.5.8](/zh/news/releases/1.5.x/announcing-1.5.8) 或更高的版本。
* 对于 1.6.x deployments: 部署： 请升级至 [Istio 1.6.5](/zh/news/releases/1.6.x/announcing-1.6.5) 或更高的版本。

{{< boilerplate "security-vulnerability" >}}
